{{ config(materialized=dbt_bigquery_monitoring_materialization(), enabled=false, tags=["dbt-bigquery-monitoring-information-schema-by-folder"]) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-storage-usage-by-folder -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.TABLE_STORAGE_USAGE_TIMELINE_BY_FOLDER view, you
need the following Identity and Access Management (IAM) permissions for the parent folder of the project:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
roles/bigquery.admin
For more information about BigQuery permissions, see
BigQuery IAM roles and permissions. -#}

SELECT
usage_date,
folder_numbers,
project_id,
table_catalog,
project_number,
table_schema,
table_name,
billable_total_logical_usage,
billable_active_logical_usage,
billable_long_term_logical_usage,
billable_total_physical_usage,
billable_active_physical_usage,
billable_long_term_physical_usage
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE_USAGE_TIMELINE_BY_FOLDER`
