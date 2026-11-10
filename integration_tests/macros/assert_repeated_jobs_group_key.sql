{% macro assert_repeated_jobs_group_key(expected) %}
  {% set actual = dbt_bigquery_monitoring.repeated_jobs_group_key() | trim %}
  {% if actual != (expected | trim) %}
    {% do exceptions.raise_compiler_error(
      "Expected [" ~ (expected | trim) ~ "] but got [" ~ actual ~ "]"
    ) %}
  {% endif %}
{% endmacro %}
