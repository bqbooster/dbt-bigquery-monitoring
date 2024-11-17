{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    partition_by = {
      "field": "hour",
      "data_type": "timestamp",
      "granularity": "hour",
      "copy_partitions": should_use_copy_partitions()
    },
    cluster_by = ["query"],
    partition_expiration_days = var('lookback_window_days')
    )
}}
SELECT
  hour,
  query,
  APPROX_TOP_COUNT(project_id, 100) AS project_ids,
  APPROX_TOP_COUNT(reservation_id, 100) AS reservation_ids,
  APPROX_TOP_COUNT(user_email, 100) AS user_emails,
  COUNTIF(cache_hit) AS cache_hit,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNT(*) AS query_count
FROM
  {{ jobs_done_incremental_hourly() }}
GROUP BY hour, query