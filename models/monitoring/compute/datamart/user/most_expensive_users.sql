{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  TIMESTAMP_TRUNC(HOUR, DAY) AS day,
  user_email,
  SUM(ROUND(total_query_cost, 2)) / SUM(query_count) AS avg_query_cost,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  SUM(query_count) AS query_count
FROM {{ ref('most_expensive_users_incremental') }}
GROUP BY day, user_email
ORDER BY total_query_cost DESC
LIMIT {{ var('output_limit_size') }}
