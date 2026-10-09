import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"
PARTITIONS_MODEL = (
    REPO_ROOT / "models" / "information_schema" / "tables" / "information_schema_partitions.sql"
)
BATCHED_MATERIALIZATION = REPO_ROOT / "macros" / "materialization_information_schema_batched_table.sql"
PARTITIONS_MACROS = REPO_ROOT / "macros" / "information_schema_partitions.sql"


def _dbt_env() -> dict[str, str]:
    env = os.environ.copy()
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


def test_chunk_list_splits_and_keeps_remainder() -> None:
    result = _run_operation(
        "assert_chunk_list",
        args={
            "values": ["t1", "t2", "t3", "t4", "t5"],
            "chunk_size": 2,
            "expected": [["t1", "t2"], ["t3", "t4"], ["t5"]],
        },
    )

    assert result.returncode == 0, _output(result)


def test_chunk_list_keeps_small_lists_unsplit() -> None:
    result = _run_operation(
        "assert_chunk_list",
        args={
            "values": ["t1", "t2"],
            "chunk_size": 900,
            "expected": [["t1", "t2"]],
        },
    )

    assert result.returncode == 0, _output(result)


def test_empty_table_list_emits_no_jobs() -> None:
    result = _run_operation(
        "assert_partitions_jobs_for_dataset",
        args={
            "dataset": "`sample-project`.`sample_dataset`",
            "table_names": [],
            "batch_size": 900,
            "expected_job_count": 0,
            "expect_table_filter": False,
        },
    )

    assert result.returncode == 0, _output(result)


def test_small_dataset_keeps_unfiltered_partitions_scan() -> None:
    result = _run_operation(
        "assert_partitions_jobs_for_dataset",
        args={
            "dataset": "`sample-project`.`sample_dataset`",
            "table_names": [f"table_{i}" for i in range(900)],
            "batch_size": 900,
            "expected_job_count": 1,
            "expect_table_filter": False,
        },
    )

    assert result.returncode == 0, _output(result)


def test_oversized_dataset_batches_table_name_filters() -> None:
    table_names = [f"table_{i}" for i in range(1801)]
    result = _run_operation(
        "assert_partitions_jobs_for_dataset",
        args={
            "dataset": "`sample-project`.`sample_dataset`",
            "table_names": table_names,
            "batch_size": 900,
            "expected_job_count": 3,
            "expect_table_filter": True,
        },
    )

    assert result.returncode == 0, _output(result)


def test_select_sql_quotes_table_names_for_unnest() -> None:
    result = _run_operation(
        "assert_partitions_select_contains",
        args={
            "dataset": "`sample-project`.`sample_dataset`",
            "table_names": ["foo", "o'bar"],
            "needle": "WHERE table_name IN UNNEST(['foo', 'o''bar'])",
        },
    )

    assert result.returncode == 0, _output(result)


def test_batch_size_default_and_override() -> None:
    default_result = _run_operation("assert_partitions_table_batch_size", args={"expected": 900})
    assert default_result.returncode == 0, _output(default_result)

    override_result = _run_operation(
        "assert_partitions_table_batch_size",
        args={"expected": 500},
        dbt_vars={"partitions_table_batch_size": 500},
    )
    assert override_result.returncode == 0, _output(override_result)


def test_rejects_batch_size_above_bigquery_limit() -> None:
    result = _run_operation(
        "expect_partitions_table_batch_size_error",
        dbt_vars={"partitions_table_batch_size": 1001},
    )

    assert result.returncode != 0
    assert "between 1 and 1000" in _output(result)


def test_batched_materialization_sets_relation_types_for_fusion() -> None:
    source = BATCHED_MATERIALIZATION.read_text()

    assert "this.incorporate(type='table')" in source
    assert "existing_relation.incorporate(type='table')" in source
    assert "dbt_bigquery_monitoring.information_schema_partitions_job_sqls()" in source
    assert "INSERT INTO {{ target_relation }}" in source


def test_partitions_model_uses_batched_materialization_by_default() -> None:
    model = PARTITIONS_MODEL.read_text()
    macros = PARTITIONS_MACROS.read_text()

    assert "materialized=dbt_bigquery_monitoring.information_schema_partitions_materialization()" in model
    assert "information_schema_batched_table" in macros
    assert "WHERE table_name IN UNNEST" in macros
    assert "UNION ALL" in macros
    assert "get_dataset_list()" in model
