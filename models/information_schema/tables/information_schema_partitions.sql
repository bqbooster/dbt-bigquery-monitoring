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


{% set preflight_sql -%}
SELECT
CONCAT('`', CATALOG_NAME, '`.`', SCHEMA_NAME, '`') AS SCHEMA_NAME
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
{%- endset %}
{% set results = run_query(preflight_sql) %}
{% set dataset_list = results | map(attribute='SCHEMA_NAME') | list %}
{%- if dataset_list | length == 0 -%}
{{ log("No datasets found in the project list", info=False) }}
{%- endif -%}

WITH base AS (
{%- if dataset_list | length == 0 -%}
  SELECT CAST(NULL AS STRING) AS table_catalog, CAST(NULL AS STRING) AS table_schema, CAST(NULL AS STRING) AS table_name, CAST(NULL AS STRING) AS partition_id, CAST(NULL AS INTEGER) AS total_rows, CAST(NULL AS INTEGER) AS total_logical_bytes, CAST(NULL AS TIMESTAMP) AS last_modified_time, CAST(NULL AS STRING) AS storage_tier
  LIMIT 0
{%- else %}
{% for dataset in dataset_list -%}
  SELECT
  table_catalog,
table_schema,
table_name,
partition_id,
total_rows,
total_logical_bytes,
last_modified_time,
storage_tier
  FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`PARTITIONS`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
{%- endif -%}
)

SELECT
table_catalog,
table_schema,
table_name,
partition_id,
total_rows,
total_logical_bytes,
last_modified_time,
storage_tier,
FROM
base
