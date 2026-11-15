{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-write-api -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.WRITE_API_TIMELINE view, you need
the bigquery.tables.list Identity and Access Management (IAM) permission for the
project.Each of the following predefined IAM roles includes the required
permission:
roles/bigquery.user
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.dataOwner
roles/bigquery.metadataViewer
roles/bigquery.resourceAdmin
roles/bigquery.admin
Caution: The required
  `bigquery.tables.list` permission is not included in the basic roles Owner or Editor.
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
start_timestamp,
project_id,
project_number,
dataset_id,
table_id,
stream_type,
error_code,
total_requests,
total_rows,
total_input_bytes
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`WRITE_API_TIMELINE`
