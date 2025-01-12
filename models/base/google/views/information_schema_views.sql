{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-views -#}
{# Required role/permissions: To get view metadata, you need the following Identity and Access Management (IAM)
permissions:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the
permissions that you need in order to get view metadata:
roles/bigquery.admin
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
roles/bigquery.dataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
table_catalog,
table_schema,
table_name,
view_definition,
check_option,
use_standard_sql
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`VIEWS`
