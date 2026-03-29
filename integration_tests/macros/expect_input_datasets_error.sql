{% macro expect_input_datasets_error() %}
  {% do dbt_bigquery_monitoring.get_dataset_list() %}
{% endmacro %}
