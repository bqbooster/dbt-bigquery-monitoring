from pathlib import Path

from test_input_datasets_validation import _output, _run_operation


REPO_ROOT = Path(__file__).resolve().parents[1]
MACRO = REPO_ROOT / "macros" / "gcp_bigquery_audit_logs_optional_column.sql"
V2_MODEL = REPO_ROOT / "models" / "monitoring" / "base" / "bigquery_audit_logs_v2.sql"
WRAPPER = REPO_ROOT / "models" / "monitoring" / "base" / "bigquery_audit_logs.sql"
JOBS_FROM_AUDIT_LOGS = REPO_ROOT / "models" / "monitoring" / "base" / "jobs_from_audit_logs.sql"
OPTIONAL_FIXTURE = (
    REPO_ROOT
    / "integration_tests"
    / "models"
    / "gcp_bigquery_audit_logs_fixture_without_optional_columns.sql"
)
WORKFLOWS = [
    REPO_ROOT / ".github" / "workflows" / "pr_run_models.yml",
    REPO_ROOT / ".github" / "workflows" / "pr_run_models_fusion.yml",
]


def test_optional_column_macro_is_parse_safe_and_typed_for_fusion() -> None:
    source = MACRO.read_text()

    assert "gcp_bigquery_audit_logs_should_inspect_sink" in source
    assert "{% if not execute %}" in source
    assert "flags.WHICH | default('')" in source
    assert "which in ['run', 'build', 'retry']" in source
    assert "adapter.get_relation(" in source
    assert "adapter.get_columns_in_relation(" in source
    assert "incorporate(type='table')" in source
    assert "CAST(NULL AS {{ data_type }}) AS {{ column_name }}" in source
    assert "run_query(" not in source
    assert "get_relation" in source.split("gcp_bigquery_audit_logs_source_column_names()")[1]
    inspect_macro, lookup_macro = source.split("{% macro gcp_bigquery_audit_logs_source_column_names() %}")
    assert "adapter.get_relation(" not in inspect_macro
    assert "adapter.get_relation(" in lookup_macro
    assert "gcp_bigquery_audit_logs_should_inspect_sink()" in lookup_macro


def test_sink_lookup_is_not_gated_by_execute_alone() -> None:
    source = MACRO.read_text()
    lookup = source.split("{% macro gcp_bigquery_audit_logs_source_column_names() %}")[1]

    assert "if not gcp_bigquery_audit_logs_should_inspect_sink()" in lookup
    assert "{% if not execute %}" not in lookup
    assert "{% if execute %}" not in lookup
    for command in ("compile", "docs", "list", "show", "parse", "test", "run-operation"):
        assert f"'{command}'" not in source.split("which in")[1].split("\n")[0]


def test_v2_model_projects_optional_sink_columns_through_macro() -> None:
    source = V2_MODEL.read_text()

    assert "gcp_bigquery_audit_logs_source_column_names()" in source
    assert "gcp_bigquery_audit_logs_optional_column(" in source
    assert "'labels'" in source
    assert "'errorGroups'" in source
    assert "ARRAY<STRUCT<key STRING, value STRING>>" in source
    assert "ARRAY<STRUCT<id STRING>>" in source
    assert "    labels,\n" not in source
    assert "    errorGroups,\n" not in source


def test_jobs_from_audit_logs_read_labels_from_metadata_json() -> None:
    source = JOBS_FROM_AUDIT_LOGS.read_text()

    assert "JSON_QUERY(protopayload_auditlog.metadataJson, '$.labels')" in source
    assert "FROM {{ ref('bigquery_audit_logs') }}" in source
    assert "UNNEST(labels)" not in source


def test_wrapper_still_selects_optional_columns() -> None:
    source = WRAPPER.read_text()

    assert "  labels,\n  errorGroups\n" in source
    assert "FROM {{ ref('bigquery_audit_logs_v2') }}" in source


def test_fixture_omits_top_level_labels_and_error_groups() -> None:
    source = OPTIONAL_FIXTURE.read_text()

    assert "tags=['fixtures']" in source
    assert "NULL AS errorGroups" not in source
    assert "AS key, 'prod' AS value)] AS labels" not in source
    assert "AS key, 'staging' AS value)] AS labels" not in source
    assert "resource" in source
    assert "protopayload_auditlog" in source


def test_core_and_fusion_ci_cover_sink_without_optional_columns() -> None:
    for workflow in WORKFLOWS:
        text = workflow.read_text()
        assert "gcp_bigquery_audit_logs_fixture_without_optional_columns" in text, workflow.name
        assert "DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_TABLE=" in text, workflow.name
        assert "dbt compile -s jobs_from_audit_logs" in text, workflow.name


def test_run_operation_does_not_inspect_the_sink() -> None:
    result = _run_operation("assert_audit_logs_sink_inspect_gated")

    assert result.returncode == 0, _output(result)
