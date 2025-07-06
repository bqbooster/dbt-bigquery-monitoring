{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    partition_by = {
      "field": "hour",
      "data_type": "timestamp",
      "granularity": "hour",
      "copy_partitions": dbt_bigquery_monitoring_variable_use_copy_partitions()
    },
    cluster_by = ["user_email"],
    partition_expiration_days = dbt_bigquery_monitoring_variable_lookback_window_days()
    )
}}
SELECT
  hour,
  user_email,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNT(*) AS query_count,
  COUNTIF(cache_hit) AS cache_hit,
  COUNTIF(error_result IS NOT NULL) AS failed_queries,
  COUNT(DISTINCT project_id) AS projects_used,
  COUNT(DISTINCT reservation_id) AS reservations_used,
  AVG(total_time_seconds) AS avg_duration_seconds,
  SUM(total_bytes_processed) AS total_bytes_processed,
  -- Job type breakdown
  APPROX_TOP_SUM(job_type, 1, 20) AS job_types
FROM {{ jobs_done_incremental_hourly() }}
GROUP BY hour, user_email
