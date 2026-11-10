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


def test_project_mode_schemata_lookup_unions_each_project() -> None:
    result = _run_operation(
        "assert_schemata_lookup_sql",
        dbt_vars={"input_gcp_projects": ["proj-a", "proj-b"], "bq_region": "eu"},
        args={
            "required": [
                "FROM `proj-a`.`region-eu`.`INFORMATION_SCHEMA`.`SCHEMATA`",
                "FROM `proj-b`.`region-eu`.`INFORMATION_SCHEMA`.`SCHEMATA`",
                "UNION ALL",
            ],
            "forbidden": ["FROM `region-eu`.`INFORMATION_SCHEMA`.`SCHEMATA`"],
        },
    )

    assert result.returncode == 0, _output(result)
