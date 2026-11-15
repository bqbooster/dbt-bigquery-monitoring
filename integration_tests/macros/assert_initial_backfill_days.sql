{% macro assert_initial_backfill_days(expected) %}
  {% set actual = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_initial_backfill_days() %}
  {% if actual != expected %}
    {% do exceptions.raise_compiler_error(
      "Expected initial_backfill_days " ~ expected ~ " but got " ~ actual
    ) %}
  {% endif %}
{% endmacro %}
