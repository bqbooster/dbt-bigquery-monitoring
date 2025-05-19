{{
   config(
    materialized='table',
    )
}}

WITH model_aggregates AS (
  SELECT
    dbt_model_name,
    ARRAY_CONCAT_AGG(project_ids) AS aggregated_project_ids,
    ARRAY_CONCAT_AGG(reservation_ids) AS aggregated_reservation_ids,
    ARRAY_CONCAT_AGG(user_emails) AS aggregated_user_emails,
    SUM(cache_hit) / SUM(query_count) AS cache_hit_ratio,
    SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
    SUM(total_slot_ms) AS total_slot_ms,
    SUM(query_count) AS query_count,
    SUM(cache_hit) AS cache_hit
  FROM
    {{ ref('models_costs_incremental') }}
  GROUP BY dbt_model_name
)

SELECT
  dbt_model_name,
  {{ top_sum('aggregated_project_ids') }} AS project_ids,
  {{ top_sum('aggregated_reservation_ids') }} AS reservation_ids,
  {{ top_sum('aggregated_user_emails') }} AS user_emails,
  cache_hit_ratio,
  total_query_cost,
  total_slot_ms,
  query_count,
  cache_hit
FROM model_aggregates
WHERE query_count > 1
ORDER BY query_count DESC
LIMIT {{ var('output_limit_size') }}
