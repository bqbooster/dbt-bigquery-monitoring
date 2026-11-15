{% macro assert_chunk_list(values, chunk_size, expected) %}
  {% set actual = dbt_bigquery_monitoring.chunk_list(values, chunk_size) %}
  {% if actual != expected %}
    {% do exceptions.raise_compiler_error(
      "Expected " ~ (expected | tojson) ~ " but got " ~ (actual | tojson)
    ) %}
  {% endif %}
{% endmacro %}

{% macro assert_partitions_jobs_for_dataset(dataset, table_names, batch_size, expected_job_count, expect_table_filter) %}
  {% set jobs = dbt_bigquery_monitoring.information_schema_partitions_jobs_for_dataset(
    dataset,
    table_names,
    batch_size
  ) %}

  {% if jobs | length != expected_job_count %}
    {% do exceptions.raise_compiler_error(
      "Expected " ~ expected_job_count ~ " PARTITIONS jobs but got " ~ (jobs | length)
      ~ " sql=" ~ (jobs | tojson)
    ) %}
  {% endif %}

  {% for job_sql in jobs %}
    {% set has_filter = 'WHERE table_name IN UNNEST(' in job_sql %}
    {% if expect_table_filter and not has_filter %}
      {% do exceptions.raise_compiler_error(
        "Expected table_name IN UNNEST filter in job SQL: " ~ job_sql
      ) %}
    {% endif %}
    {% if not expect_table_filter and has_filter %}
      {% do exceptions.raise_compiler_error(
        "Expected unfiltered PARTITIONS scan for a small dataset, got: " ~ job_sql
      ) %}
    {% endif %}
    {% if dataset | trim not in job_sql %}
      {% do exceptions.raise_compiler_error(
        "Expected dataset " ~ dataset ~ " in job SQL: " ~ job_sql
      ) %}
    {% endif %}
  {% endfor %}
{% endmacro %}

{% macro assert_partitions_select_contains(dataset, table_names, needle) %}
  {% set sql = dbt_bigquery_monitoring.information_schema_partitions_select_sql(dataset, table_names) %}
  {% if needle not in sql %}
    {% do exceptions.raise_compiler_error(
      "Expected " ~ needle ~ " in " ~ sql
    ) %}
  {% endif %}
{% endmacro %}

{% macro expect_partitions_table_batch_size_error() %}
  {% do dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_partitions_table_batch_size() %}
{% endmacro %}

{% macro assert_partitions_job_sql_count(dataset_list, batch_size, expected_job_count) %}
  {% set jobs = dbt_bigquery_monitoring.information_schema_partitions_job_sqls(dataset_list, batch_size) %}
  {% if jobs | length != expected_job_count %}
    {% do exceptions.raise_compiler_error(
      "Expected " ~ expected_job_count ~ " PARTITIONS jobs but got " ~ (jobs | length)
      ~ " sql=" ~ (jobs | tojson)
    ) %}
  {% endif %}
{% endmacro %}

{% macro assert_project_by_project_column_csv(column_names, expected) %}
  {% set actual = dbt_bigquery_monitoring.project_by_project_column_csv(column_names) %}
  {% if actual != expected %}
    {% do exceptions.raise_compiler_error(
      "Expected column csv " ~ expected ~ " but got " ~ actual
    ) %}
  {% endif %}
{% endmacro %}

{% macro assert_configuration_materialization(expected) %}
  {% set actual = dbt_bigquery_monitoring.dbt_bigquery_monitoring_configuration_materialization() %}
  {% if actual != expected %}
    {% do exceptions.raise_compiler_error(
      "Expected configuration materialization " ~ expected ~ " but got " ~ actual
    ) %}
  {% endif %}
{% endmacro %}

{% macro assert_schemata_discovery(schema_names, error_messages, expected_datasets, expected_error_count) %}
  {% set parsed = dbt_bigquery_monitoring.datasets_from_schemata_columns(schema_names, error_messages) %}
  {% if parsed['datasets'] != expected_datasets %}
    {% do exceptions.raise_compiler_error(
      "Expected datasets " ~ (expected_datasets | tojson) ~ " but got " ~ (parsed['datasets'] | tojson)
    ) %}
  {% endif %}
  {% if parsed['errors'] | length != expected_error_count %}
    {% do exceptions.raise_compiler_error(
      "Expected " ~ expected_error_count ~ " discovery errors but got " ~ (parsed['errors'] | tojson)
    ) %}
  {% endif %}
{% endmacro %}

{% macro expect_schemata_discovery_failure(schema_names, error_messages) %}
  {% set parsed = dbt_bigquery_monitoring.datasets_from_schemata_columns(schema_names, error_messages) %}
  {% do dbt_bigquery_monitoring.raise_if_schemata_discovery_failed(parsed) %}
{% endmacro %}

{% macro expect_schemata_lookup_error() %}
  {% do dbt_bigquery_monitoring.information_schema_schemata_lookup_sql() %}
{% endmacro %}

{% macro assert_partitions_table_batch_size(expected) %}
  {% set actual = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_partitions_table_batch_size() %}
  {% if actual != expected %}
    {% do exceptions.raise_compiler_error(
      "Expected partitions_table_batch_size " ~ expected ~ " but got " ~ actual
    ) %}
  {% endif %}
{% endmacro %}
