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


def test_project_by_project_table_uses_initial_backfill_days() -> None:
    source = MATERIALIZATION.read_text()
    variables = (REPO_ROOT / "macros" / "variables.sql").read_text()

    assert "INTERVAL 166 DAY" not in source
    assert source.count("initial_backfill_days") >= 4
    assert "dbt_bigquery_monitoring_variable_initial_backfill_days()" in source
    assert "DBT_BQ_MONITORING_INITIAL_BACKFILL_DAYS" in variables
    assert "166" in variables
    assert "backfill_days > 166" in variables
