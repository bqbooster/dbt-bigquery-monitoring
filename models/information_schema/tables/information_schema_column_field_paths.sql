{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-column-field-paths -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.COLUMN_FIELD_PATHS view, you need the following
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
field_path,
data_type,
description,
collation_name,
rounding_mode,
policy_tags
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`COLUMN_FIELD_PATHS`
