{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}

  CREATE TEMP FUNCTION TOP_SUM(arr ANY TYPE) AS ((
  SELECT APPROX_TOP_SUM(c.value, c.count, 100) FROM UNNEST(arr) c
));
{%- endcall %}
SELECT
  query,
  TOP_SUM(ARRAY_CONCAT_AGG(project_ids)) AS project_ids,
  TOP_SUM(ARRAY_CONCAT_AGG(reservation_ids)) AS reservation_ids,
  TOP_SUM(ARRAY_CONCAT_AGG(user_emails)) AS user_emails,
  SUM(cache_hit) / SUM(query_count) AS cache_hit_ratio,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  SUM(query_count) AS query_count,
  SUM(cache_hit) AS cache_hit,
FROM
  {{ ref('most_repeated_jobs_incremental') }}
GROUP BY query
HAVING query_count > 1
ORDER BY query_count DESC
LIMIT {{ var('output_limit_size') }}
