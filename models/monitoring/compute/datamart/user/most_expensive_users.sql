{{
   config(
    materialized='view',
    )
}}
SELECT
  TIMESTAMP_TRUNC(HOUR, DAY) AS day,
  user_email,
  SUM(ROUND(total_query_cost, 2)) / SUM(query_count) AS avg_query_cost,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  SUM(query_count) AS query_count
FROM {{ ref('users_costs_incremental') }}
GROUP BY day, user_email
ORDER BY total_query_cost DESC
LIMIT {{ var('output_limit_size') }}
