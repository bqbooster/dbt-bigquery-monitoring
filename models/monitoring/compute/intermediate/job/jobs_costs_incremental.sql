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
    cluster_by = ["hour", "query"],
    partition_expiration_days = var('lookback_window_days')
    )
}}

WITH base AS (
  SELECT
  hour,
  project_id,
  reservation_id,
  job_id,
  query,
  user_email,
  cache_hit,
  query_cost,
  total_slot_ms,
  total_time_seconds,
  RANK() OVER (PARTITION BY hour ORDER BY query_cost DESC) AS rank_cost,
  RANK() OVER (PARTITION BY hour ORDER BY total_time_seconds DESC) AS rank_duration
FROM {{ jobs_done_incremental_hourly() }}
)

SELECT
  hour,
  query,
  ARRAY_AGG(
    STRUCT(
      project_id,
      reservation_id,
      job_id,
      user_email,
      cache_hit,
      query_cost,
      total_slot_ms,
      total_time_seconds,
      rank_cost,
      rank_duration
    )
  ) AS jobs,
  COUNTIF(cache_hit) AS cache_hit,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNT(*) AS query_count
FROM base
GROUP BY hour, query
