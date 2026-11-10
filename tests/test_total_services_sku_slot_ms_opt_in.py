"""total_services_sku_slot_ms stays opt-in and is not selected by default.

The column is null unless the job has external service costs billed as
SERVICES_SKU. The generated INFORMATION_SCHEMA SQL already wraps it in
dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms().
"""

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def test_total_services_sku_slot_ms_defaults_off() -> None:
    project = (REPO_ROOT / "dbt_project.yml").read_text()
    variables = (REPO_ROOT / "macros" / "variables.sql").read_text()
    jobs_sql = (
        REPO_ROOT / "models" / "information_schema" / "jobs" / "information_schema_jobs.sql"
    ).read_text()
    jobs_with_cost = (
        REPO_ROOT / "models" / "monitoring" / "base" / "jobs_with_cost.sql"
    ).read_text()

    assert "enable_total_services_sku_slot_ms: false" in project
    assert (
        "dbt_bigquery_monitoring_variable_priority('enable_total_services_sku_slot_ms', "
        "'DBT_BQ_MONITORING_ENABLE_TOTAL_SERVICES_SKU_SLOT_MS', false)"
        in variables
    )
    assert "enable_experimental_fields()" not in variables.split(
        "dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms"
    )[1].split("{% endmacro %}")[0]
    assert "dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms()" in jobs_sql
    assert "total_services_sku_slot_ms" in jobs_with_cost
    assert "dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms()" in jobs_with_cost
