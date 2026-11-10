import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"
GROUP_KEY_ENV = "DBT_BQ_MONITORING_GROUP_REPEATED_JOBS_BY_NORMALIZED_HASH"


def _run_operation(macro_name: str, *, dbt_vars=None, args=None) -> subprocess.CompletedProcess[str]:
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
    env.pop(GROUP_KEY_ENV, None)
    command = ["dbt", "run-operation", macro_name]
    if args is not None:
        command.extend(["--args", json.dumps(args)])
    if dbt_vars is not None:
        command.extend(["--vars", json.dumps(dbt_vars)])
    return subprocess.run(
        command,
        cwd=INTEGRATION_TESTS_DIR,
        env=env,
        text=True,
        capture_output=True,
    )


def _output(result: subprocess.CompletedProcess[str]) -> str:
    return result.stdout + result.stderr


def test_repeated_jobs_stay_grouped_by_query_text_by_default() -> None:
    result = _run_operation(
        "assert_repeated_jobs_group_key",
        args={"expected": "hour, query"},
    )
    assert result.returncode == 0, _output(result)


def test_repeated_jobs_group_by_normalized_hash_when_enabled() -> None:
    result = _run_operation(
        "assert_repeated_jobs_group_key",
        dbt_vars={"group_repeated_jobs_by_normalized_hash": True},
        args={"expected": "hour, query_fingerprint"},
    )
    assert result.returncode == 0, _output(result)
