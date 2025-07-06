{{
   config(
    materialized='view',
    )
}}
SELECT
  query,
  APPROX_TOP_SUM(j.project_id, 1, 100) AS project_ids,
  APPROX_TOP_SUM(j.reservation_id, 1, 100) AS reservation_ids,
  APPROX_TOP_SUM(j.user_email, 1, 100) AS user_emails,
  SUM(t.cache_hit) / SUM(t.query_count) AS cache_hit_ratio,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(t.total_slot_ms) AS total_slot_ms,
  SUM(t.query_count) AS query_count,
  SUM(t.cache_hit) AS cache_hit,
FROM {{ ref('jobs_costs_incremental') }} AS t, UNNEST(jobs) AS j
GROUP BY query
HAVING query_count > 1
ORDER BY query_count DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
