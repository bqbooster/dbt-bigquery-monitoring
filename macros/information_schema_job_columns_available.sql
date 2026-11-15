{#-
  Audit-log-only mode synthesizes query_info and job_stages as bare NULLs,
  which BigQuery types as INT64. Nested field access is valid only when the
  column comes from INFORMATION_SCHEMA (region mode, or audit logs combined
  with INFORMATION_SCHEMA).
-#}
{% macro information_schema_job_columns_available() %}
    {{ return(
        not dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs()
        or should_combine_audit_logs_and_information_schema()
    ) }}
{% endmacro %}
