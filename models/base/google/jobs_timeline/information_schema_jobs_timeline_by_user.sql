{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs-timeline-by-user -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.JOBS_TIMELINE_BY_USER view, you need the
bigquery.jobs.list Identity and Access Management (IAM) permission for the project.
Each of the following predefined IAM roles includes the required
permission:
Project Viewer
BigQuery User
For more information about BigQuery permissions, see
Access control with IAM. -#}
WITH base AS (
{% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT * FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_TIMELINE_BY_USER`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT * FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_TIMELINE_BY_USER`
{%- endif %}
)
SELECT
period_start,
period_slot_ms,
period_shuffle_ram_usage_ratio,
project_id,
project_number,
user_email,
job_id,
job_type,
statement_type,
job_creation_time,
job_start_time,
job_end_time,
state,
reservation_id,
total_bytes_processed,
error_result,
cache_hit,
period_estimated_runnable_units,
FROM
  base
