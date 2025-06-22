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
  COUNTIF(cache_hit) AS cache_hit,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNT(*) AS query_count,
  -- Enhanced dbt model tracking
  COUNTIF(error_result IS NOT NULL) AS failed_runs,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SUM(total_bytes_billed) AS total_bytes_billed,
  AVG(total_time_seconds) AS avg_duration_seconds,
  MAX(total_time_seconds) AS max_duration_seconds,
  MIN(total_time_seconds) AS min_duration_seconds,
  -- Model complexity indicators
  AVG(total_slot_ms) AS avg_slot_ms,
  -- Performance percentiles
  APPROX_QUANTILES(total_time_seconds, 100)[OFFSET(50)] AS median_duration_seconds,
  APPROX_QUANTILES(total_time_seconds, 100)[OFFSET(90)] AS p90_duration_seconds,
  -- Resource efficiency
  SUM(total_bytes_processed) / NULLIF(SUM(total_slot_ms), 0) AS bytes_per_slot_ms
FROM
  {{ jobs_done_incremental_hourly() }}
WHERE dbt_model_name IS NOT NULL
GROUP BY hour, dbt_model_name
