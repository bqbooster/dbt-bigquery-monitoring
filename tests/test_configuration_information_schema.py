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
PROJECT_MODELS = {
    "information_schema_effective_project_options.sql",
    "information_schema_project_options.sql",
    "information_schema_project_options_changes.sql",
}


def test_configuration_models_keep_previous_enablement() -> None:
    sql_files = sorted(CONFIG_DIR.glob("*.sql"))
    assert {path.name for path in sql_files} == ORGANIZATION_MODELS | PROJECT_MODELS

    for path in sql_files:
        source = path.read_text()
        assert "enabled=false" not in source, path.name
        if path.name in ORGANIZATION_MODELS:
            # Organization views are not project-scoped. Project mode must not
            # rewrite them to `project.region-*.INFORMATION_SCHEMA`.
            assert "materialized=" not in source, path.name
            assert "dbt-bigquery-monitoring-information-schema-by-organization" not in source, path.name
        else:
            assert "materialized=dbt_bigquery_monitoring_configuration_materialization()" in source, path.name


def test_failover_history_stays_disabled() -> None:
    source = (
        Path(__file__).resolve().parents[1]
        / "models"
        / "information_schema"
        / "reservations"
        / "information_schema_failover_history.sql"
    ).read_text()
    assert "enabled=false" in source
    assert "materialized=dbt_bigquery_monitoring_materialization()" in source
