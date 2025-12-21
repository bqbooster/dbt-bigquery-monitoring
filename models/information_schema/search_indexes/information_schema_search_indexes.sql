{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-indexes -#}
{# Required role/permissions: To see search index metadata, you need the
bigquery.tables.get or bigquery.tables.list Identity and Access Management (IAM)
permission on the table with the index. Each of the following predefined
IAM roles includes at least one of these permissions:
roles/bigquery.admin
roles/bigquery.dataEditor
roles/bigquery.dataOwner
roles/bigquery.dataViewer
roles/bigquery.metadataViewer
roles/bigquery.user
For more information about BigQuery permissions, see
Access control with IAM. -#}


{% set dataset_list = get_dataset_list() %}

WITH base AS (
{%- if dataset_list | length == 0 -%}
  SELECT CAST(NULL AS STRING) AS index_catalog, CAST(NULL AS STRING) AS index_schema, CAST(NULL AS STRING) AS table_name, CAST(NULL AS STRING) AS index_name, CAST(NULL AS STRING) AS index_status, CAST(NULL AS TIMESTAMP) AS creation_time, CAST(NULL AS TIMESTAMP) AS last_modification_time, CAST(NULL AS TIMESTAMP) AS last_refresh_time, CAST(NULL AS TIMESTAMP) AS disable_time, CAST(NULL AS STRING) AS disable_reason, CAST(NULL AS STRING) AS ddl, CAST(NULL AS INTEGER) AS coverage_percentage, CAST(NULL AS INTEGER) AS unindexed_row_count, CAST(NULL AS INTEGER) AS total_logical_bytes, CAST(NULL AS INTEGER) AS total_storage_bytes, CAST(NULL AS STRING) AS analyzer
  LIMIT 0
{%- else %}
{% for dataset in dataset_list -%}
  SELECT
  index_catalog,
index_schema,
table_name,
index_name,
index_status,
creation_time,
last_modification_time,
last_refresh_time,
disable_time,
disable_reason,
ddl,
coverage_percentage,
unindexed_row_count,
total_logical_bytes,
total_storage_bytes,
analyzer
  FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`SEARCH_INDEXES`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
{%- endif -%}
)

SELECT
index_catalog,
index_schema,
table_name,
index_name,
index_status,
creation_time,
last_modification_time,
last_refresh_time,
disable_time,
disable_reason,
ddl,
coverage_percentage,
unindexed_row_count,
total_logical_bytes,
total_storage_bytes,
analyzer
FROM
base
