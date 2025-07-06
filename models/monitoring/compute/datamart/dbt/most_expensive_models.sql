{{
   config(
    materialized='view',
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
  {{ top_sum_from_count('aggregated_project_ids') }} AS project_ids,
  {{ top_sum_from_count('aggregated_reservation_ids') }} AS reservation_ids,
  {{ top_sum_from_count('aggregated_user_emails') }} AS user_emails,
  cache_hit_ratio,
  total_query_cost,
  total_slot_ms,
  query_count,
  cache_hit
FROM model_aggregates
ORDER BY total_query_cost DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
