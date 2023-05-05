{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  user_email,
  AVG(query_cost) AS avg_query_cost,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  COUNT(*) AS query_count
FROM {{ ref('jobs_by_project_with_cost') }}
GROUP BY user_email
ORDER BY query_cost DESC
LIMIT {{ var('output_limit_size') }}
