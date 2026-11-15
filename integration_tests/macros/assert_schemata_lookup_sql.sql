{% macro assert_schemata_lookup_sql(required, forbidden) %}
  {% set actual = dbt_bigquery_monitoring.information_schema_schemata_lookup_sql() %}
  {% for needle in required %}
    {% if needle not in actual %}
      {% do exceptions.raise_compiler_error(
        "Expected schemata lookup to contain " ~ needle ~ " but got " ~ actual
      ) %}
    {% endif %}
  {% endfor %}
  {% for needle in forbidden %}
    {% if needle in actual %}
      {% do exceptions.raise_compiler_error(
        "Expected schemata lookup to omit " ~ needle ~ " but got " ~ actual
      ) %}
    {% endif %}
  {% endfor %}
{% endmacro %}
