{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-index-column-options -#}
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


{% set preflight_sql -%}
SELECT
CONCAT('`', CATALOG_NAME, '`.`', SCHEMA_NAME, '`') AS SCHEMA_NAME
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
{%- endset %}
{% set results = run_query(preflight_sql) %}
{% set dataset_list = results | map(attribute='SCHEMA_NAME') | list %}
{%- if dataset_list | length == 0 -%}
{{ log("No datasets found in the project list", info=False) }}
{%- endif -%}

WITH base AS (
{%- if dataset_list | length == 0 -%}
  SELECT CAST(NULL AS STRING) AS index_catalog, CAST(NULL AS STRING) AS index_schema, CAST(NULL AS STRING) AS table_name, CAST(NULL AS STRING) AS index_name, CAST(NULL AS STRING) AS column_name, CAST(NULL AS STRING) AS option_name, CAST(NULL AS STRING) AS option_type, CAST(NULL AS STRING) AS option_value
  LIMIT 0
{%- else %}
{% for dataset in dataset_list -%}
  SELECT
  index_catalog,
index_schema,
table_name,
index_name,
column_name,
option_name,
option_type,
option_value
  FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`SEARCH_INDEX_COLUMN_OPTIONS`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
{%- endif -%}
)
SELECT
index_catalog,
index_schema,
table_name,
index_name,
column_name,
option_name,
option_type,
option_value
FROM
base
