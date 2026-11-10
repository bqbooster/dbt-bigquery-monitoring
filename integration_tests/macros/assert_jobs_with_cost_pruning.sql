{% macro assert_jobs_with_cost_pruning(expected) %}
  {% set actual = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_enable_jobs_with_cost_partition_pruning() %}
  {% if actual != expected %}
    {% do exceptions.raise_compiler_error(
      "Expected jobs_with_cost pruning " ~ expected ~ " but got " ~ actual
    ) %}
  {% endif %}
{% endmacro %}
