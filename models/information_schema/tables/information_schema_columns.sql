{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-columns -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.COLUMNS view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.admin
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
table_catalog,
table_schema,
table_name,
column_name,
ordinal_position,
is_nullable,
data_type,
is_generated,
generation_expression,
is_stored,
is_hidden,
is_updatable,
is_system_defined,
is_partitioning_column,
clustering_ordinal_position,
collation_name,
column_default,
rounding_mode,
policy_tags
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`COLUMNS`
