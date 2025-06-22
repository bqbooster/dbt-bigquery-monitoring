{{
   config(
    materialized='view',
    )
}}
SELECT
  TIMESTAMP_TRUNC(HOUR, DAY) AS day,
  user_email,
  ROUND(SUM(total_query_cost) / NULLIF(SUM(query_count), 0), 4) AS avg_query_cost,
  ROUND(SUM(total_query_cost), 2) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  SUM(query_count) AS query_count,
  ROUND(SUM(total_slot_ms) / NULLIF(SUM(query_count), 0) / 1000, 2) AS avg_slot_seconds_per_query,
  SUM(cache_hit) / NULLIF(SUM(query_count), 0) AS cache_hit_ratio
FROM {{ ref('users_costs_incremental') }}
GROUP BY day, user_email
ORDER BY total_query_cost DESC
LIMIT {{ var('output_limit_size') }}
