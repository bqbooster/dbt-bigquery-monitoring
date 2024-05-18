{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs-by-folder -#}
{# Required role/permissions: 
    
      To get the permission that you need to query the INFORMATION_SCHEMA.JOBS_BY_FOLDER view,
    
      ask your administrator to grant you the
    
  
  BigQuery Resource Viewer  (roles/bigquery.resourceViewer) IAM role on your parent folder.
  

  
  
  For more information about granting roles, see Manage access.
  
   -#}
WITH base AS (
{% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT * FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_BY_FOLDER`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT * FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_BY_FOLDER`
{%- endif %}
)
SELECT
bi_engine_statistics,
cache_hit,
creation_time,
destination_table,
end_time,
error_result,
folder_numbers,
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
query_info,
FROM
  base
