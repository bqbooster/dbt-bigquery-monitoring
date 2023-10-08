{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    partition_by = {
      "field": "hour",
      "data_type": "timestamp",
      "granularity": "hour"
    },
    cluster_by = ["dbt_model_name"],
    partition_expiration_days = var('lookback_window_days')
    )
}}
SELECT
  hour,
  dbt_model_name,
  APPROX_TOP_COUNT(project_id, 100) AS project_ids,
  APPROX_TOP_COUNT(reservation_id, 100) AS reservation_ids,
  APPROX_TOP_COUNT(user_email, 100) AS user_emails,
  COUNTIF(cache_hit) cache_hit,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNT(*) AS amount
FROM
  {{ ref('jobs_incremental') }}
WHERE dbt_model_name IS NOT NULL
GROUP BY hour, dbt_model_name
