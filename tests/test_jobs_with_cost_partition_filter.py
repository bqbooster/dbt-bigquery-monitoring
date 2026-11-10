"""The jobs_with_cost creation_time filter must sit above the window.

INFORMATION_SCHEMA.JOBS and the project-mode jobs table are partitioned by
creation_time. BigQuery does not push a predicate through a window function,
so a downstream incremental WHERE still scans the whole jobs history.
"""

from pathlib import Path


SQL = (
    Path(__file__).resolve().parents[1]
    / "models"
    / "monitoring"
    / "base"
    / "jobs_with_cost.sql"
).read_text()


def test_creation_time_filter_is_applied_before_the_parent_script_window() -> None:
    source_filter = SQL.index("INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() + 1 }} DAY")
    window = SQL.index("MAX(dbt_info_extracted) OVER")
    output_filter = SQL.index("statement_type != 'SCRIPT'")

    assert source_filter < window < output_filter
    assert SQL.count("MAX(dbt_info_extracted) OVER") == 1
    assert "creation_time >=" in SQL[source_filter - 200 : source_filter]
    assert "lookback_window_days() }} DAY" in SQL[output_filter : output_filter + 400]
