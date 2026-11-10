from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
MATERIALIZATION = REPO_ROOT / "macros" / "project_by_project_table.sql"


def test_project_by_project_table_sets_relation_types_for_fusion() -> None:
    """dbt Fusion raises dbt1005 'relation has no type' unless relations are typed.

    See https://github.com/bqbooster/dbt-bigquery-monitoring/issues/202
    and dbt-labs/dbt-fusion#769 (drop_relation requires relation_type).
    """
    source = MATERIALIZATION.read_text()

    assert "this.incorporate(type='table')" in source
    assert "make_temp_relation(this).incorporate(type='table')" in source
    assert "old_relation" not in source
    assert (
        "existing_relation is not none and not adapter.is_replaceable(" in source
    ), "Must not call drop_relation/is_replaceable when the relation is missing"


def parse_initial_backfill_days(raw: object) -> int:
    """Same rules as dbt_bigquery_monitoring_variable_initial_backfill_days."""
    if isinstance(raw, str):
        text = raw.strip()
        if text == "" or any(char not in "0123456789" for char in text):
            raise ValueError(f"initial_backfill_days must be an integer from 1 to 166, got: {raw}")
        days = int(text)
    elif isinstance(raw, bool) or raw is None or not isinstance(raw, (int, float)):
        raise ValueError(f"initial_backfill_days must be an integer from 1 to 166, got: {raw}")
    elif float(raw) != int(raw):
        raise ValueError(f"initial_backfill_days must be an integer from 1 to 166, got: {raw}")
    else:
        days = int(raw)
    if days < 1 or days > 166:
        raise ValueError(
            "initial_backfill_days must be an integer from 1 to 166 "
            f"(BigQuery allows 4000 partitions per hourly INSERT; 166 days is 3984 hours), got: {raw}"
        )
    return days


def test_project_by_project_table_uses_initial_backfill_days() -> None:
    source = MATERIALIZATION.read_text()
    variables = (REPO_ROOT / "macros" / "variables.sql").read_text()
    macro = variables.split("macro dbt_bigquery_monitoring_variable_initial_backfill_days()", 1)[1]
    macro = macro.split("endmacro", 1)[0]

    assert "INTERVAL 166 DAY" not in source
    assert "lookback_window_days" not in source
    assert source.count("initial_backfill_days") >= 4
    assert "dbt_bigquery_monitoring_variable_initial_backfill_days()" in source
    # Incremental catch-up still floors at the same 166-day window unless the var changes.
    assert source.count("GREATEST(TIMESTAMP_TRUNC(") == 1
    assert "INTERVAL ' ~ initial_backfill_days ~ ' DAY" in source
    assert source.count("INTERVAL ' ~ initial_backfill_days ~ ' DAY") == 3
    assert "DBT_BQ_MONITORING_INITIAL_BACKFILL_DAYS" in macro
    assert "'initial_backfill_days', 'DBT_BQ_MONITORING_INITIAL_BACKFILL_DAYS', 166" in macro
    assert "parsed.days < 1 or parsed.days > 166" in macro
    assert "char not in '0123456789'" in macro


def test_initial_backfill_days_rejects_out_of_range_and_non_integers() -> None:
    assert parse_initial_backfill_days(166) == 166
    assert parse_initial_backfill_days(1) == 1
    assert parse_initial_backfill_days("166") == 166
    assert parse_initial_backfill_days(" 7 ") == 7
    assert parse_initial_backfill_days(166.0) == 166

    for raw in (0, -1, 167, "0", "-1", "167", "166.5", "abc", "", "  ", "166 days", True, None, 166.5):
        try:
            parse_initial_backfill_days(raw)
        except ValueError as error:
            assert "1 to 166" in str(error)
            assert str(raw) in str(error) or raw in ("", "  ")
        else:
            raise AssertionError(f"expected {raw!r} to be rejected")
