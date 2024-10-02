{#-- macro to control the copy_partitions usage at project level for this package #}
{% macro should_use_copy_partitions() -%}
  {{ return(var('dbt_bigquery_monitoring_use_copy_partitions', true)) }}
{%- endmacro %}
