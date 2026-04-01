import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"


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


def test_accepts_single_string_input_dataset() -> None:
    result = _run_operation(
        "assert_input_datasets",
        dbt_vars={"input_datasets": " sample-project.sample_dataset "},
        args={"expected": ["`sample-project`.`sample_dataset`"]},
    )

    assert result.returncode == 0, _output(result)


def test_accepts_list_input_datasets() -> None:
    result = _run_operation(
        "assert_input_datasets",
        dbt_vars={
            "input_datasets": [
                "sample-project.sample_dataset",
                "sample-project.second_dataset",
            ]
        },
        args={
            "expected": [
                "`sample-project`.`sample_dataset`",
                "`sample-project`.`second_dataset`",
            ]
        },
    )

    assert result.returncode == 0, _output(result)


def test_rejects_malformed_input_dataset_shape() -> None:
    result = _run_operation(
        "expect_input_datasets_error",
        dbt_vars={"input_datasets": "sample-project.sample_dataset.extra"},
    )

    assert result.returncode != 0
    output = _output(result)
    assert "input_datasets entries" in output
    assert "project.dataset" in output


def test_rejects_unsupported_input_dataset_type() -> None:
    result = _run_operation(
        "expect_input_datasets_error",
        dbt_vars={"input_datasets": 123},
    )

    assert result.returncode != 0
    output = _output(result)
    assert "input_datasets" in output
    assert "string or list of project.dataset values" in output


def test_rejects_invalid_project_and_dataset_characters() -> None:
    invalid_cases = [
        ("sample`project.sample_dataset", "project"),
        ("sample-project.sample;dataset", "dataset"),
    ]

    for value, invalid_part in invalid_cases:
        result = _run_operation(
            "expect_input_datasets_error",
            dbt_vars={"input_datasets": value},
        )

        assert result.returncode != 0
        assert f"input_datasets {invalid_part} identifiers may contain only" in _output(result)
