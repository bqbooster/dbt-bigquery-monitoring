{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs-timeline -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.JOBS_TIMELINE view, you need the
bigquery.jobs.listAll Identity and Access Management (IAM) permission for the project.
Each of the following predefined IAM roles includes the required
permission:
Project Owner
BigQuery Admin
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT period_start, period_slot_ms, project_id, project_number, user_email, job_id, job_type, statement_type, priority, parent_job_id, job_creation_time, job_start_time, job_end_time, state, reservation_id, edition, total_bytes_billed, total_bytes_processed, error_result, cache_hit, period_shuffle_ram_usage_ratio, period_estimated_runnable_units, transaction_id
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_TIMELINE`
