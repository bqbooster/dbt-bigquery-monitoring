{% macro assert_input_datasets(expected) %}
  {% set actual = dbt_bigquery_monitoring.get_dataset_list() %}

  {% if actual != expected %}
    {% do exceptions.raise_compiler_error(
      "Expected " ~ (expected | tojson) ~
      " but got " ~ (actual | tojson)
    ) %}
  {% endif %}
{% endmacro %}
