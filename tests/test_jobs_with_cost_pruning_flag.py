"""The pruning flag defaults off, including the string form of an environment variable."""

import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"


def _env(**overrides: str) -> dict[str, str]:
    env = os.environ.copy()
    env.pop("DBT_BQ_MONITORING_ENABLE_JOBS_WITH_COST_PARTITION_PRUNING", None)
    env.update(
        {
            "DBT_PROFILES_DIR": ".",
            "DBT_ENV_SECRET_BIGQUERY_TEST_STORAGE_PROJECT": "dummy-project",
            "DBT_ENV_SECRET_BIGQUERY_TEST_EXECUTION_PROJECT": "dummy-project",
            "DBT_ENV_SECRET_BIGQUERY_TEST_LOCATION": "us",
            "GITHUB_SHA": "local",
        }
    )
    env.update(overrides)
    return env


def _assert_flag(expected: bool, *, dbt_vars=None, env=None) -> None:
    command = [
        "dbt",
        "run-operation",
        "assert_jobs_with_cost_pruning",
        "--args",
        json.dumps({"expected": expected}),
    ]
    if dbt_vars is not None:
        command.extend(["--vars", json.dumps(dbt_vars)])
    result = subprocess.run(
        command,
        cwd=INTEGRATION_TESTS_DIR,
        env=env or _env(),
        text=True,
        capture_output=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr


def test_jobs_with_cost_pruning_defaults_off() -> None:
    _assert_flag(False)
    _assert_flag(False, dbt_vars={"enable_jobs_with_cost_partition_pruning": False})
    _assert_flag(False, dbt_vars={"enable_jobs_with_cost_partition_pruning": "false"})
    _assert_flag(True, dbt_vars={"enable_jobs_with_cost_partition_pruning": True})
    _assert_flag(True, dbt_vars={"enable_jobs_with_cost_partition_pruning": "true"})
    _assert_flag(
        False,
        env=_env(DBT_BQ_MONITORING_ENABLE_JOBS_WITH_COST_PARTITION_PRUNING="false"),
    )
    _assert_flag(
        True,
        dbt_vars={"enable_jobs_with_cost_partition_pruning": False},
        env=_env(DBT_BQ_MONITORING_ENABLE_JOBS_WITH_COST_PARTITION_PRUNING="true"),
    )
