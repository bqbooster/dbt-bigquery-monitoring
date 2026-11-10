{{ config(materialized=dbt_bigquery_monitoring_materialization(), enabled=false, tags=["dbt-bigquery-monitoring-information-schema-by-folder"]) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-streaming-by-folder -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.STREAMING_TIMELINE_BY_FOLDER view, you need
the bigquery.tables.list Identity and Access Management (IAM) permission for the parent
folder of the project.Each of the following predefined IAM roles includes the preceding
permission:
roles/bigquery.admin
roles/bigquery.user
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.dataOwner
roles/bigquery.metadataViewer
roles/bigquery.resourceAdmin
Caution: The required
  `bigquery.tables.list` permission is not included in the basic roles Owner or Editor.
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
start_timestamp,
folder_numbers,
project_id,
project_number,
dataset_id,
table_id,
error_code,
total_requests,
total_rows,
total_input_bytes
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`STREAMING_TIMELINE_BY_FOLDER`
