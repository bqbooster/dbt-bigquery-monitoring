"""total_services_sku_slot_ms stays selected unless a project turns it off.

The column is null unless the job has external service costs billed as
SERVICES_SKU. The generated INFORMATION_SCHEMA SQL already wraps it in
dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms().
The package default remains true, and an unset value still follows
enable_experimental_fields.
"""

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def test_total_services_sku_slot_ms_stays_on_by_default() -> None:
    project = (REPO_ROOT / "dbt_project.yml").read_text()
    variables = (REPO_ROOT / "macros" / "variables.sql").read_text()
    jobs_sql = (
        REPO_ROOT / "models" / "information_schema" / "jobs" / "information_schema_jobs.sql"
    ).read_text()
    jobs_with_cost = (
        REPO_ROOT / "models" / "monitoring" / "base" / "jobs_with_cost.sql"
    ).read_text()
    macro = variables.split(
        "macro dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms()",
        1,
    )[1].split("{% endmacro %}", 1)[0]

    assert "enable_total_services_sku_slot_ms: true" in project
    assert "enable_total_services_sku_slot_ms: false" not in project
    assert "dbt_bigquery_monitoring_variable_enable_experimental_fields()" in macro
    assert (
        "dbt_bigquery_monitoring_variable_priority('enable_total_services_sku_slot_ms', "
        "'DBT_BQ_MONITORING_ENABLE_TOTAL_SERVICES_SKU_SLOT_MS', "
        "dbt_bigquery_monitoring_variable_enable_experimental_fields())"
        in macro
    )
    assert "dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms()" in jobs_sql
    assert "total_services_sku_slot_ms" in jobs_with_cost
    assert "dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms()" in jobs_with_cost
