{% macro assert_slot_hour_price_sql(expected) %}
  {% set actual = dbt_bigquery_monitoring.dbt_bigquery_monitoring_slot_hour_price_sql() | trim %}
  {% if actual != (expected | trim) %}
    {% do exceptions.raise_compiler_error(
      "Expected [" ~ (expected | trim) ~ "] but got [" ~ actual ~ "]"
    ) %}
  {% endif %}
{% endmacro %}

{% macro assert_slot_hour_price_sql_contains(tokens) %}
  {% set actual = dbt_bigquery_monitoring.dbt_bigquery_monitoring_slot_hour_price_sql() | trim %}
  {% for token in tokens %}
    {% if token not in actual %}
      {% do exceptions.raise_compiler_error(
        "Missing [" ~ token ~ "] in [" ~ actual ~ "]"
      ) %}
    {% endif %}
  {% endfor %}
{% endmacro %}

{% macro assert_slot_hour_price_sql_excludes(tokens) %}
  {% set actual = dbt_bigquery_monitoring.dbt_bigquery_monitoring_slot_hour_price_sql() | trim %}
  {% for token in tokens %}
    {% if token in actual %}
      {% do exceptions.raise_compiler_error(
        "Unexpected [" ~ token ~ "] in [" ~ actual ~ "]"
      ) %}
    {% endif %}
  {% endfor %}
{% endmacro %}
