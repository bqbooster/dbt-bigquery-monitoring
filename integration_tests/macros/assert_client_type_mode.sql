{% macro assert_client_type_mode(expected) %}
  {% set actual = dbt_bigquery_monitoring.client_type_detection_mode() | trim %}
  {% if actual != (expected | trim) %}
    {% do exceptions.raise_compiler_error(
      "Expected [" ~ (expected | trim) ~ "] but got [" ~ actual ~ "]"
    ) %}
  {% endif %}
{% endmacro %}
