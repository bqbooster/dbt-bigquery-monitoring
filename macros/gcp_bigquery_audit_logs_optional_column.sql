{#
  Inspect the configured Cloud Logging BigQuery sink and emit either the real
  column or a typed NULL.

  Cloud Logging only creates sink columns after a log entry has used that field.
  Optional LogEntry fields such as `labels` and `errorGroups` are therefore often
  missing. Selecting them unconditionally fails the audit-log models (#207).

  Parse / compile (execute is false): Fusion's parse adapter returns an empty
  column list from get_columns_in_relation, so this path must not assume the
  column exists. Typed CAST(NULL AS ...) keeps compile/parse valid on Core and
  Fusion without adapter metadata calls.

  Run (execute is true): look up the sink via get_relation + get_columns_in_relation.
  Missing tables and missing columns both fall back to CAST(NULL AS <type>).
  Relations are typed for Fusion (see #202).
#}
{% macro gcp_bigquery_audit_logs_source_column_names() %}
  {% if not execute %}
    {{ return([]) }}
  {% endif %}

  {% set relation = adapter.get_relation(
      database=dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_storage_project(),
      schema=dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_dataset(),
      identifier=dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_table()
  ) %}

  {% if relation is none %}
    {{ return([]) }}
  {% endif %}

  {% set typed_relation = relation.incorporate(type='table') %}
  {% set columns = adapter.get_columns_in_relation(typed_relation) %}
  {% set names = [] %}
  {% for column in columns %}
    {% do names.append(column.name | lower) %}
  {% endfor %}
  {{ return(names) }}
{% endmacro %}

{%- macro gcp_bigquery_audit_logs_optional_column(column_name, data_type, source_column_names=none) -%}
  {%- if source_column_names is none -%}
    {%- set source_column_names = gcp_bigquery_audit_logs_source_column_names() -%}
  {%- endif -%}
  {%- if (column_name | lower) in source_column_names -%}
    {{ column_name }}
  {%- else -%}
    CAST(NULL AS {{ data_type }}) AS {{ column_name }}
  {%- endif -%}
{%- endmacro -%}
