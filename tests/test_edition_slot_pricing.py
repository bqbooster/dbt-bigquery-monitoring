import json
import os
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
INTEGRATION_TESTS_DIR = REPO_ROOT / "integration_tests"

PRICING_ENV_VARS = (
    "DBT_BQ_MONITORING_HOURLY_SLOT_PRICE",
    "DBT_BQ_MONITORING_USE_EDITION_SLOT_PRICING",
    "DBT_BQ_MONITORING_SLOT_PRICING_PLAN",
    "DBT_BQ_MONITORING_STANDARD_PAYG_SLOT_PRICE",
    "DBT_BQ_MONITORING_STANDARD_COMMITMENT_1Y_SLOT_PRICE",
    "DBT_BQ_MONITORING_STANDARD_COMMITMENT_3Y_SLOT_PRICE",
    "DBT_BQ_MONITORING_ENTERPRISE_PAYG_SLOT_PRICE",
    "DBT_BQ_MONITORING_ENTERPRISE_COMMITMENT_1Y_SLOT_PRICE",
    "DBT_BQ_MONITORING_ENTERPRISE_COMMITMENT_3Y_SLOT_PRICE",
    "DBT_BQ_MONITORING_ENTERPRISE_PLUS_PAYG_SLOT_PRICE",
    "DBT_BQ_MONITORING_ENTERPRISE_PLUS_COMMITMENT_1Y_SLOT_PRICE",
    "DBT_BQ_MONITORING_ENTERPRISE_PLUS_COMMITMENT_3Y_SLOT_PRICE",
)


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
    for key in PRICING_ENV_VARS:
        env.pop(key, None)
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


def test_default_slot_price_is_the_historical_flat_rate() -> None:
    result = _run_operation(
        "assert_slot_hour_price_sql",
        args={"expected": "0.04"},
    )
    assert result.returncode == 0, _output(result)

    unchanged = _run_operation(
        "assert_slot_hour_price_sql_excludes",
        args={"tokens": ["CASE", "edition", "STANDARD", "ENTERPRISE"]},
    )
    assert unchanged.returncode == 0, _output(unchanged)


def test_payg_edition_case_uses_published_list_rates() -> None:
    result = _run_operation(
        "assert_slot_hour_price_sql_contains",
        dbt_vars={"use_edition_slot_pricing": True, "slot_pricing_plan": "pay_as_you_go"},
        args={
            "tokens": [
                "UPPER(CAST(edition AS STRING))",
                "WHEN 'STANDARD' THEN 0.04",
                "WHEN 'ENTERPRISE' THEN 0.06",
                "WHEN 'ENTERPRISE_PLUS' THEN 0.1",
                "WHEN 'ENTERPRISE PLUS' THEN 0.1",
                "ELSE 0.04",
            ]
        },
    )
    assert result.returncode == 0, _output(result)

    no_reservation = _run_operation(
        "assert_slot_hour_price_sql_excludes",
        dbt_vars={"use_edition_slot_pricing": True},
        args={"tokens": ["reservation_id"]},
    )
    assert no_reservation.returncode == 0, _output(no_reservation)


def test_commitment_plan_uses_commitment_rates() -> None:
    result = _run_operation(
        "assert_slot_hour_price_sql_contains",
        dbt_vars={"use_edition_slot_pricing": True, "slot_pricing_plan": "commitment_1_year"},
        args={
            "tokens": [
                "WHEN 'STANDARD' THEN 0.036",
                "WHEN 'ENTERPRISE' THEN 0.048",
                "WHEN 'ENTERPRISE_PLUS' THEN 0.08",
            ]
        },
    )
    assert result.returncode == 0, _output(result)


def test_reservation_override_selects_that_reservations_plan() -> None:
    result = _run_operation(
        "assert_slot_hour_price_sql_contains",
        dbt_vars={
            "use_edition_slot_pricing": True,
            "slot_pricing_plan": "pay_as_you_go",
            "reservation_slot_pricing_plans": {
                "admin-project:US.etl": "commitment_3_year",
                "O'Brien:US.adhoc": "pay_as_you_go",
            },
        },
        args={
            "tokens": [
                "WHEN reservation_id = 'admin-project:US.etl'",
                "WHEN 'ENTERPRISE' THEN 0.036",
                "WHEN 'STANDARD' THEN 0.032",
                "WHEN 'ENTERPRISE_PLUS' THEN 0.06",
                "WHEN reservation_id = 'O''Brien:US.adhoc'",
                "ELSE",
            ]
        },
    )
    assert result.returncode == 0, _output(result)


def test_rejects_unknown_pricing_plan() -> None:
    result = _run_operation(
        "assert_slot_hour_price_sql",
        dbt_vars={"use_edition_slot_pricing": True, "slot_pricing_plan": "monthly"},
        args={"expected": "unused"},
    )
    assert result.returncode != 0
    assert "slot_pricing_plan" in _output(result)


def test_rejects_non_mapping_reservation_overrides() -> None:
    result = _run_operation(
        "assert_slot_hour_price_sql",
        dbt_vars={
            "use_edition_slot_pricing": True,
            "reservation_slot_pricing_plans": "admin-project:US.etl",
        },
        args={"expected": "unused"},
    )
    assert result.returncode != 0
    assert "reservation_slot_pricing_plans" in _output(result)
