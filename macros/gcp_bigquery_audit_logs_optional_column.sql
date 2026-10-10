{#
  Inspect the configured Cloud Logging BigQuery sink and emit either the real
  column or a typed NULL.

  Cloud Logging only creates sink columns after a log entry has used that field.
  Optional LogEntry fields such as `labels` and `errorGroups` are therefore often
  missing. Selecting them unconditionally fails the audit-log models (#207).

  The sink lookup (get_relation + get_columns_in_relation) runs only while
  models are being materialized. `execute` is also True during `dbt compile`
  (and docs generate / show / etc.), so `execute` alone is not enough.

  Command gate (Core and Fusion): `flags.WHICH` is the current CLI task.
  Fusion exposes it the same way Core does (this package already serializes
  `which=flags.WHICH` in query comments; Fusion issue reproductions use
  `flags.WHICH` comparisons). `| default('')` covers Fusion gaps such as
  missing flag attributes (see flags.EMPTY). Allowed values: run, build,
  retry. compile, docs, list, show, parse, test, run-operation, and similar
  skip the warehouse metadata calls.

  When the lookup is skipped, compiled SQL selects
  CAST(NULL AS <type>) AS <column>. That SQL is valid, but it can differ
  from run/build SQL when the sink actually has the column.
#}
{% macro gcp_bigquery_audit_logs_should_inspect_sink() %}
  {% if not execute %}
    {{ return(false) }}
  {% endif %}

  {% set which = flags.WHICH | default('') | lower %}
  {{ return(which in ['run', 'build', 'retry']) }}
{% endmacro %}

{% macro gcp_bigquery_audit_logs_source_column_names() %}
  {% if not gcp_bigquery_audit_logs_should_inspect_sink() %}
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
