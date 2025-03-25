{{ config(materialized=dbt_bigquery_monitoring_materialization(), partition_by={'field': 'creation_time', 'data_type': 'timestamp', 'granularity': 'hour'}, partition_expiration_days=180) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs -#}
{# Required role/permissions: 

      To get the permission that you need to query the INFORMATION_SCHEMA.JOBS view,

      ask your administrator to grant you the


  BigQuery Resource Viewer  (roles/bigquery.resourceViewer) IAM role on your project.




  For more information about granting roles, see Manage access to projects, folders, and organizations.

   -#}

SELECT
bi_engine_statistics,
cache_hit,
creation_time,
destination_table,
end_time,
error_result,
job_id,
job_stages,
job_type,
labels,
parent_job_id,
priority,
project_id,
project_number,
query,
referenced_tables,
reservation_id,
edition,
session_info,
start_time,
state,
statement_type,
timeline,
total_bytes_billed,
total_bytes_processed,
total_modified_partitions,
total_slot_ms,
transaction_id,
user_email,
transferred_bytes,
materialized_view_statistics,
metadata_cache_statistics,
job_creation_reason,
query_info
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_BY_PROJECT`
