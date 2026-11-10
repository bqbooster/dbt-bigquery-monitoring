import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"


def _dbt_env() -> dict[str, str]:
    env = os.environ.copy()
    # Env vars outrank dbt --vars. Drop project/region overrides so the test
    # controls discovery through vars alone.
    env.pop("DBT_BQ_MONITORING_GCP_PROJECTS", None)
    env.pop("DBT_BQ_MONITORING_REGION", None)
    env.update(
        {
            "DBT_PROFILES_DIR": ".",
            "DBT_ENV_SECRET_BIGQUERY_TEST_STORAGE_PROJECT": "dummy-project",
            "DBT_ENV_SECRET_BIGQUERY_TEST_EXECUTION_PROJECT": "dummy-project",
            "DBT_ENV_SECRET_BIGQUERY_TEST_LOCATION": "us",
            "GITHUB_SHA": "local",
        }
    )
    return env


def _run_operation(macro_name: str, *, dbt_vars=None, args=None) -> subprocess.CompletedProcess[str]:
    command = ["dbt", "run-operation", macro_name]
    if args is not None:
        command.extend(["--args", json.dumps(args)])
    if dbt_vars is not None:
        command.extend(["--vars", json.dumps(dbt_vars)])

    return subprocess.run(
        command,
        cwd=INTEGRATION_TESTS_DIR,
        env=_dbt_env(),
        text=True,
        capture_output=True,
    )


def _output(result: subprocess.CompletedProcess[str]) -> str:
    return result.stdout + result.stderr


def test_without_projects_schemata_lookup_uses_execution_region() -> None:
    result = _run_operation(
        "assert_schemata_lookup_sql",
        args={
            "required": ["FROM `region-us`.`INFORMATION_SCHEMA`.`SCHEMATA`"],
            "forbidden": ["UNION ALL", "`.`region-"],
        },
    )

    assert result.returncode == 0, _output(result)


def test_project_mode_schemata_lookup_isolates_each_project() -> None:
    result = _run_operation(
        "assert_schemata_lookup_sql",
        dbt_vars={"input_gcp_projects": ["proj-a", "proj-b"], "bq_region": "eu"},
        args={
            "required": [
                "FROM `proj-a`.`region-eu`.`INFORMATION_SCHEMA`.`SCHEMATA`",
                "FROM `proj-b`.`region-eu`.`INFORMATION_SCHEMA`.`SCHEMATA`",
                "EXCEPTION WHEN ERROR",
                "CREATE TEMP TABLE `_dbt_bq_monitoring_schemata`",
            ],
            "forbidden": [
                "FROM `region-eu`.`INFORMATION_SCHEMA`.`SCHEMATA`",
                "UNION ALL",
            ],
        },
    )

    assert result.returncode == 0, _output(result)


def test_region_mode_configuration_models_stay_views() -> None:
    result = _run_operation(
        "assert_configuration_materialization",
        args={"expected": "view"},
    )

    assert result.returncode == 0, _output(result)


def test_project_mode_configuration_models_are_tables() -> None:
    result = _run_operation(
        "assert_configuration_materialization",
        dbt_vars={"input_gcp_projects": ["proj-a"]},
        args={"expected": "project_by_project_table"},
    )

    assert result.returncode == 0, _output(result)


def test_explicit_configuration_materialization_is_honored() -> None:
    result = _run_operation(
        "assert_configuration_materialization",
        dbt_vars={"google_information_schema_model_materialization": "ephemeral"},
        args={"expected": "ephemeral"},
    )

    assert result.returncode == 0, _output(result)


def test_one_project_discovery_error_keeps_the_other_datasets() -> None:
    result = _run_operation(
        "assert_schemata_discovery",
        args={
            "schema_names": ["`proj-a`.`analytics`", None],
            "error_messages": [None, "Access Denied: project proj-b"],
            "expected_datasets": ["`proj-a`.`analytics`"],
            "expected_error_count": 1,
        },
    )

    assert result.returncode == 0, _output(result)

    kept = _run_operation(
        "expect_schemata_discovery_failure",
        args={
            "schema_names": ["`proj-a`.`analytics`", None],
            "error_messages": [None, "Access Denied: project proj-b"],
        },
    )
    assert kept.returncode == 0, _output(kept)


def test_discovery_failure_on_every_project_raises() -> None:
    result = _run_operation(
        "expect_schemata_discovery_failure",
        args={
            "schema_names": [None, None],
            "error_messages": ["Access Denied: proj-a", "Access Denied: proj-b"],
        },
    )

    assert result.returncode != 0
    assert "Could not list datasets for any input project" in _output(result)


def test_project_id_with_statement_break_is_rejected() -> None:
    result = _run_operation(
        "expect_schemata_lookup_error",
        dbt_vars={"input_gcp_projects": ["proj`;drop"], "bq_region": "us"},
    )

    assert result.returncode != 0
    assert "project ids" in _output(result)
