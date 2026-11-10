"""jobs_with_cost pruning is opt-in. The default view matches the previous SQL.

INFORMATION_SCHEMA.JOBS and the project-mode jobs table are partitioned by
creation_time. BigQuery does not push a predicate through a window function,
so the prune filter has to sit above MAX(...) OVER. Leaving it off keeps
project-mode history, region-mode INFORMATION_SCHEMA retention, audit logs,
and incremental catch-up from _dbt_max_partition.
"""

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SQL_PATH = REPO_ROOT / "models" / "monitoring" / "base" / "jobs_with_cost.sql"
# The view as it exists on main. CI checks out the pull request with a shallow
# history, so the comparison cannot depend on `git show main:...`.
BASELINE_PATH = REPO_ROOT / "tests" / "fixtures" / "jobs_with_cost_without_pruning.sql"
SQL = SQL_PATH.read_text()


def _without_pruning_blocks(sql: str) -> str:
    return re.sub(
        r"\n\{%- if dbt_bigquery_monitoring_variable_enable_jobs_with_cost_partition_pruning\(\) %\}.*?\{%- endif %\}",
        "",
        sql,
        flags=re.S,
    )


def _normalize(sql: str) -> str:
    return "\n".join(line.rstrip() for line in sql.strip().splitlines()) + "\n"


def test_default_jobs_with_cost_sql_matches_the_previous_view() -> None:
    baseline = BASELINE_PATH.read_text()

    assert _normalize(_without_pruning_blocks(SQL)) == _normalize(baseline)
    assert "enable_jobs_with_cost_partition_pruning" not in baseline
    assert "_dbt_max_partition" not in SQL


def test_pruning_filter_sits_above_the_parent_script_window() -> None:
    source_filter = SQL.index(
        "INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() + 1 }} DAY"
    )
    window = SQL.index("MAX(dbt_info_extracted) OVER")
    output_filter = SQL.index("statement_type != 'SCRIPT'")

    assert source_filter < window < output_filter
    assert SQL.count("MAX(dbt_info_extracted) OVER") == 1
    assert SQL.count("dbt_bigquery_monitoring_variable_enable_jobs_with_cost_partition_pruning()") == 2
    assert "creation_time >=" in SQL[source_filter - 200 : source_filter]
    assert "lookback_window_days() }} DAY" in SQL[output_filter : output_filter + 500]


def test_pruning_defaults_off_and_does_not_follow_the_billing_window() -> None:
    variables = (REPO_ROOT / "macros" / "variables.sql").read_text()
    macro = variables.split(
        "macro dbt_bigquery_monitoring_variable_enable_jobs_with_cost_partition_pruning()",
        1,
    )[1].split("endmacro", 1)[0]

    assert "'enable_jobs_with_cost_partition_pruning', 'DBT_BQ_MONITORING_ENABLE_JOBS_WITH_COST_PARTITION_PRUNING', false" in macro
    assert "lookback_incremental_billing_window_days" not in SQL
    assert "initial_backfill_days" not in SQL
