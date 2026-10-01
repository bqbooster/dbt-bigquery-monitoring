import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = REPO_ROOT / "models"
MACROS_DIR = REPO_ROOT / "macros"

# `_dbt_max_partition` is NULL on an empty incremental table. Predicates that use it
# without a fallback match nothing forever (see issue #202 comment).
_MAX_PARTITION = re.compile(r"(?<![A-Za-z0-9_])_dbt_max_partition(?![A-Za-z0-9_])")
_JINJA_COMMENT = re.compile(r"\{#.*?#\}", re.DOTALL)
_FALLBACK_MARKERS = ("COALESCE", "IS NULL", "coalesce_dbt_max_partition", "get_partition_timestamp", "get_partition_logic")


def _sql_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.sql"))


def _fallback_window(source: str, match_start: int, match_end: int) -> str:
    return source[max(0, match_start - 120) : min(len(source), match_end + 120)]


def test_table_reference_incremental_coalesces_max_partition_to_lookback() -> None:
    source = (
        REPO_ROOT
        / "models"
        / "monitoring"
        / "storage"
        / "intermediate"
        / "table_reference_incremental.sql"
    ).read_text()

    assert "WHERE creation_time > COALESCE(" in source
    assert "_dbt_max_partition," in source
    assert (
        "TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)"
        in source
    )
    assert "WHERE creation_time > _dbt_max_partition\n" not in source


def test_jobs_helpers_keep_null_fallback_and_hour_default() -> None:
    source = (MACROS_DIR / "jobs_done_incremental_hourly.sql").read_text()

    assert "{% macro lower_boundary_no_data(granularity='HOUR') -%}" in source
    assert "{% macro get_partition_timestamp(granularity='HOUR') -%}" in source
    assert "WHEN _dbt_max_partition IS NULL THEN {{ lower_boundary_no_data(granularity) }}" in source
    assert "creation_time >= {{ get_partition_logic() }}" in source
    assert "coalesce_dbt_max_partition" in source


def test_compute_minute_filter_still_uses_partition_timestamp_helper() -> None:
    source = (MACROS_DIR / "compute_incremental_minute_filter.sql").read_text()
    assert "{{ get_partition_timestamp() }}" in source


def test_sql_uses_of_max_partition_include_a_null_fallback() -> None:
    offenders: list[str] = []
    for path in _sql_files(MODELS_DIR) + _sql_files(MACROS_DIR):
        source = _JINJA_COMMENT.sub("", path.read_text())
        for match in _MAX_PARTITION.finditer(source):
            window = _fallback_window(source, match.start(), match.end())
            if not any(marker in window for marker in _FALLBACK_MARKERS):
                rel = path.relative_to(REPO_ROOT)
                offenders.append(f"{rel}: {window!r}")

    assert offenders == []


def test_named_incrementals_do_not_use_raw_max_partition() -> None:
    """Models called out in #202 should go through helpers, not a bare symbol."""
    relative_paths = [
        "models/monitoring/global/datamart/daily_spend.sql",
        "models/monitoring/compute/intermediate/reservation/reservation_usage_per_minute.sql",
        "models/monitoring/compute/intermediate/billing/compute_billing_per_hour.sql",
        "models/monitoring/storage/datamart/billing/storage_billing_per_hour.sql",
    ]
    for relative in relative_paths:
        source = (REPO_ROOT / relative).read_text()
        assert _MAX_PARTITION.search(source) is None, relative
        assert (
            "coalesce_dbt_max_partition" in source or "get_partition_logic" in source
        ), relative


def test_combined_jobs_inputs_falls_back_when_max_partition_is_null() -> None:
    source = (REPO_ROOT / "models" / "monitoring" / "base" / "combined_jobs_inputs.sql").read_text()
    assert "{{ get_partition_timestamp() }}" in source
    assert "{{ lower_boundary_no_data() }}" in source
    assert "COALESCE(TIMESTAMP_TRUNC(_dbt_max_partition, HOUR), CURRENT_TIMESTAMP())" in source
    assert "TIMESTAMP_TRUNC(_dbt_max_partition, HOUR) AND TIMESTAMP_TRUNC(_dbt_max_partition, HOUR)" not in source
