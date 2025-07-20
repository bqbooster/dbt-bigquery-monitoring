{{ config(materialized=dbt_bigquery_monitoring_materialization(), enabled=false, tags=["dbt-bigquery-monitoring-information-schema-by-folder"]) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-storage-by-folder -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.TABLE_STORAGE_BY_FOLDER view, you need the
following Identity and Access Management (IAM) permissions for the parent folder of the
project:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.admin
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
For more information about BigQuery permissions, see
BigQuery IAM roles and permissions. -#}

SELECT
folder_numbers,
project_id,
project_number,
table_catalog,
table_schema,
table_name,
creation_time,
total_rows,
total_partitions,
total_logical_bytes,
active_logical_bytes,
long_term_logical_bytes,
current_physical_bytes,
total_physical_bytes,
active_physical_bytes,
long_term_physical_bytes,
time_travel_physical_bytes,
storage_last_modified_time,
deleted,
table_type,
fail_safe_physical_bytes,
last_metadata_index_refresh_time,
table_deletion_reason,
table_deletion_time
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE_BY_FOLDER`
