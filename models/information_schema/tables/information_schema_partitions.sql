{{ config(materialized=dbt_bigquery_monitoring.information_schema_partitions_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-partitions -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.PARTITIONS view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.admin
roles/bigquery.dataEditor
roles/bigquery.dataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}
{# Querying INFORMATION_SCHEMA.PARTITIONS is limited to 1000 tables per query.
   Datasets under partitions_table_batch_size (default 900) keep one unfiltered
   SELECT. Larger datasets are queried in table-name batches as separate jobs
   via information_schema_batched_table. -#}


{% set partitions_materialization = dbt_bigquery_monitoring.information_schema_partitions_materialization() %}
{% if partitions_materialization == 'information_schema_batched_table' %}
{{ dbt_bigquery_monitoring.information_schema_partitions_empty_sql() }}
{% else %}
{% set dataset_list = get_dataset_list() %}
{% set partition_jobs = dbt_bigquery_monitoring.information_schema_partitions_job_sqls(dataset_list) %}
{% if partition_jobs | length > 1 %}
  {% do exceptions.raise_compiler_error(
    "INFORMATION_SCHEMA.PARTITIONS cannot scan more than 1000 tables in one query, "
    ~ "and materialization '" ~ partitions_materialization ~ "' cannot split a large "
    ~ "dataset into multiple jobs. Unset google_information_schema_model_materialization "
    ~ "so information_schema_partitions can use information_schema_batched_table "
    ~ "(see https://github.com/bqbooster/dbt-bigquery-monitoring/issues/208)."
  ) %}
{% endif %}

WITH base AS (
{%- if partition_jobs | length == 0 -%}
{{ dbt_bigquery_monitoring.information_schema_partitions_empty_sql() }}
{%- else %}
{{ partition_jobs | join('\nUNION ALL\n') }}
{%- endif -%}
)

SELECT
table_catalog,
table_schema,
table_name,
partition_id,
total_rows,
total_logical_bytes,
total_billable_bytes,
last_modified_time,
storage_tier
FROM
base
{% endif %}
