{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}

  CREATE TEMP FUNCTION topSum(arr ANY TYPE) AS ((
  SELECT APPROX_TOP_SUM(c.value, c.count, 100) FROM UNNEST(arr) c
));
{%- endcall %}
SELECT
  query,
  topSum(ARRAY_CONCAT_AGG(project_ids)) AS project_ids,
  topSum(ARRAY_CONCAT_AGG(reservation_ids)) AS reservation_ids,
  topSum(ARRAY_CONCAT_AGG(user_emails)) AS user_emails,
  SUM(cache_hit) / SUM(amount) AS cache_hit_ratio,
  SUM(total_query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  SUM(amount) AS amount
FROM
  {{ ref('most_repeated_jobs_incremental') }}
GROUP BY query
HAVING amount > 1
ORDER BY amount DESC
LIMIT {{ var('output_limit_size') }}
