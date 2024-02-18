{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  hour,
  project_id,
  job_id,
  query,
  query_cost,
  user_email,
  total_slot_ms,
  milliseconds_to_readable_time_udf(total_slot_ms, 2) AS total_slot_time
FROM {{ ref('most_expensive_jobs_incremental') }}
ORDER BY query_cost DESC
LIMIT {{ var('output_limit_size') }}
