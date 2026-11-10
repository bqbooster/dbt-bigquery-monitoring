import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"
CLIENT_TYPE_ENV = "DBT_BQ_MONITORING_IMPROVE_CLIENT_TYPE_DETECTION"


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
    env.pop(CLIENT_TYPE_ENV, None)
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


def test_client_type_detection_stays_legacy_by_default() -> None:
    result = _run_operation(
        "assert_client_type_mode",
        args={"expected": "legacy"},
    )
    assert result.returncode == 0, _output(result)


def test_client_type_detection_can_be_enabled() -> None:
    result = _run_operation(
        "assert_client_type_mode",
        dbt_vars={"improve_client_type_detection": True},
        args={"expected": "improved"},
    )
    assert result.returncode == 0, _output(result)
