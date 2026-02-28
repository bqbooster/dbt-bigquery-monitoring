{{ config(materialized=dbt_bigquery_monitoring_materialization(), partition_by={'field': 'creation_time', 'data_type': 'timestamp', 'granularity': 'hour'}, partition_expiration_days=180) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs-by-user -#}
{# Required role/permissions: 

      To get the permission that
      you need to query the INFORMATION_SCHEMA.JOBS_BY_USER view,

      ask your administrator to grant you the




      BigQuery User  (roles/bigquery.user)
     IAM role
     on your project.






  For more information about granting roles, see Manage access to projects, folders, and organizations.

   -#}

SELECT
bi_engine_statistics,
cache_hit,
creation_time,
destination_table,
dml_statistics,
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
{%- if dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms() %}
total_services_sku_slot_ms,
{%- endif %}
transaction_id,
user_email,
{%- if dbt_bigquery_monitoring_variable_enable_principal_subject() %}
principal_subject,
{%- endif %}
transferred_bytes,
{%- if dbt_bigquery_monitoring_variable_enable_materialized_view_statistics() %}
materialized_view_statistics,
{%- endif %}
metadata_cache_statistics,
search_statistics,
query_dialect,
continuous,
vector_search_statistics,
continuous_query_info,
job_creation_reason,
query_info
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`JOBS_BY_USER`
