{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-streaming-by-folder -#}

WITH base AS (
  {% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT start_timestamp, project_id, project_number, dataset_id, table_id, error_code, total_requests, total_rows, total_input_bytes
  FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`STREAMING_TIMELINE_BY_FOLDER`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT
start_timestamp,
project_id,
project_number,
dataset_id,
table_id,
error_code,
total_requests,
total_rows,
total_input_bytes
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`STREAMING_TIMELINE_BY_FOLDER`
{%- endif %}
)

SELECT
start_timestamp,
project_id,
project_number,
dataset_id,
table_id,
error_code,
total_requests,
total_rows,
total_input_bytes,
FROM
base
