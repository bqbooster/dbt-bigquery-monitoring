{{ config(materialized=dbt_bigquery_monitoring_materialization(), partition_by={'field': 'job_creation_time', 'data_type': 'timestamp', 'granularity': 'hour'}, partition_expiration_days=180) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs-timeline -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.JOBS_TIMELINE view, you need the
bigquery.jobs.listAll Identity and Access Management (IAM) permission for the project.
Each of the following predefined IAM roles includes the required
permission:
Project Owner
BigQuery Admin
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
period_start,
period_slot_ms,
project_id,
project_number,
user_email,
{%- if dbt_bigquery_monitoring_variable_enable_principal_subject() %}
principal_subject,
{%- endif %}
job_id,
job_type,
labels,
statement_type,
priority,
parent_job_id,
job_creation_time,
job_start_time,
job_end_time,
state,
reservation_id,
edition,
total_bytes_billed,
total_bytes_processed,
error_result,
cache_hit,
period_shuffle_ram_usage_ratio,
period_estimated_runnable_units,
transaction_id
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`JOBS_TIMELINE`
