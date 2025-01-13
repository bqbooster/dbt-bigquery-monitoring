{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-vector-index-options -#}
{# Required role/permissions: To see vector index metadata, you need the
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

SELECT
index_catalog,
index_schema,
table_name,
index_name,
option_name,
option_type,
option_value
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`VECTOR_INDEX_OPTIONS`
