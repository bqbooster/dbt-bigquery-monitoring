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
  -- Additional fields for richer analysis
  job_type,
  statement_type,
  priority,
  total_bytes_processed,
  total_bytes_billed,
  error_result,
  bi_engine_statistics.bi_engine_mode,
  -- Rankings
  RANK() OVER (PARTITION BY hour ORDER BY query_cost DESC) AS rank_cost,
  RANK() OVER (PARTITION BY hour ORDER BY total_time_seconds DESC) AS rank_duration,
  RANK() OVER (PARTITION BY hour ORDER BY total_slot_ms DESC) AS rank_slot_usage
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
      job_type,
      statement_type,
      priority,
      total_bytes_processed,
      total_bytes_billed,
      error_result,
      bi_engine_mode,
      rank_cost,
      rank_duration,
      rank_slot_usage
    )
  ) AS jobs,
  COUNTIF(cache_hit) AS cache_hit,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNT(*) AS query_count,
  -- Additional aggregations
  COUNTIF(error_result IS NOT NULL) AS failed_jobs,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SUM(total_bytes_billed) AS total_bytes_billed,
  COUNT(DISTINCT project_id) AS projects_count,
  COUNT(DISTINCT user_email) AS users_count,
  AVG(total_time_seconds) AS avg_duration_seconds
FROM base
GROUP BY hour, query
