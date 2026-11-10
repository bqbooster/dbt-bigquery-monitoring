from pathlib import Path


CONFIG_DIR = (
    Path(__file__).resolve().parents[1]
    / "models"
    / "information_schema"
    / "configuration"
)

ORGANIZATION_MODELS = {
    "information_schema_organization_options.sql",
    "information_schema_organization_options_changes.sql",
}


def test_configuration_models_use_package_materialization() -> None:
    sql_files = sorted(CONFIG_DIR.glob("*.sql"))
    assert sql_files, "expected configuration INFORMATION_SCHEMA models"

    for path in sql_files:
        source = path.read_text()
        assert "materialized=dbt_bigquery_monitoring_materialization()" in source, path.name
        if path.name in ORGANIZATION_MODELS:
            assert "enabled=false" in source, path.name
            assert "dbt-bigquery-monitoring-information-schema-by-organization" in source, path.name
        else:
            assert "enabled=false" not in source, path.name
