"""initial_backfill_days defaults to the old 166-day window and rejects bad values."""

import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"


def _dbt_env(**overrides: str) -> dict[str, str]:
    env = os.environ.copy()
    env.pop("DBT_BQ_MONITORING_INITIAL_BACKFILL_DAYS", None)
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


def _assert_days(expected: int, *, dbt_vars=None, env=None) -> None:
    command = [
        "dbt",
        "run-operation",
        "assert_initial_backfill_days",
        "--args",
        json.dumps({"expected": expected}),
    ]
    if dbt_vars is not None:
        command.extend(["--vars", json.dumps(dbt_vars)])
    result = subprocess.run(
        command,
        cwd=INTEGRATION_TESTS_DIR,
        env=env or _dbt_env(),
        text=True,
        capture_output=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr


def _assert_rejected(raw_label: str, *, dbt_vars=None, env=None) -> None:
    command = [
        "dbt",
        "run-operation",
        "assert_initial_backfill_days",
        "--args",
        json.dumps({"expected": 166}),
    ]
    if dbt_vars is not None:
        command.extend(["--vars", json.dumps(dbt_vars)])
    result = subprocess.run(
        command,
        cwd=INTEGRATION_TESTS_DIR,
        env=env or _dbt_env(),
        text=True,
        capture_output=True,
    )
    output = result.stdout + result.stderr
    assert result.returncode != 0, output
    assert "initial_backfill_days must be an integer from 1 to 166" in output
    assert raw_label in output


def test_default_backfill_is_the_previous_166_day_window() -> None:
    _assert_days(166)
    _assert_days(166, dbt_vars={"initial_backfill_days": 166})
    _assert_days(166, dbt_vars={"initial_backfill_days": "166"})
    _assert_days(7, dbt_vars={"initial_backfill_days": " 7 "})
    _assert_days(166, env=_dbt_env(DBT_BQ_MONITORING_INITIAL_BACKFILL_DAYS="166"))
    # An environment variable outranks a dbt var, matching the other package settings.
    _assert_days(
        166,
        dbt_vars={"initial_backfill_days": 7},
        env=_dbt_env(DBT_BQ_MONITORING_INITIAL_BACKFILL_DAYS="166"),
    )


def test_backfill_rejects_zero_negative_too_large_and_non_integers() -> None:
    _assert_rejected("0", dbt_vars={"initial_backfill_days": 0})
    _assert_rejected("-1", dbt_vars={"initial_backfill_days": -1})
    _assert_rejected("167", dbt_vars={"initial_backfill_days": 167})
    _assert_rejected("0", dbt_vars={"initial_backfill_days": "0"})
    _assert_rejected("-1", dbt_vars={"initial_backfill_days": "-1"})
    _assert_rejected("167", dbt_vars={"initial_backfill_days": "167"})
    _assert_rejected("166.5", dbt_vars={"initial_backfill_days": "166.5"})
    _assert_rejected("abc", dbt_vars={"initial_backfill_days": "abc"})
    _assert_rejected("nope", env=_dbt_env(DBT_BQ_MONITORING_INITIAL_BACKFILL_DAYS="nope"))
