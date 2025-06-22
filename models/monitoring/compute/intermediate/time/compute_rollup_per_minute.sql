{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "minute",
      "granularity": "hour",
      "data_type": "timestamp",
      "copy_partitions": should_use_copy_partitions()
    },
    cluster_by = ['minute', 'project_id'],
    partition_expiration_days = var('output_partition_expiration_days')
    )
}}
SELECT
  TIMESTAMP_TRUNC(creation_time, MINUTE) AS minute,
  project_id,
  reservation_id,
  bi_engine_statistics.bi_engine_mode,
  client_type,
  edition,
  SUM(ROUND(query_cost, 2)) AS total_query_cost,
  SUM(IF(error_result IS NOT NULL, ROUND(query_cost, 2), 0)) AS failing_query_cost,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SUM(total_bytes_billed) AS total_bytes_billed,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNT(*) AS query_count,
  COUNT(DISTINCT user_email) AS unique_users,
  COUNT(DISTINCT session_info.session_id) AS unique_sessions,
  COUNTIF(cache_hit) AS cache_hits,
  -- Job state breakdown
  STRUCT(
    COUNTIF(state = 'DONE') AS done,
    COUNTIF(state = 'RUNNING') AS running,
    COUNTIF(state = 'PENDING') AS pending
  ) AS job_state,
    -- Job type breakdown using APPROX_TOP_SUM for flexibility
  APPROX_TOP_SUM(job_type, 1, 20) AS job_types,
  -- Statement type breakdown using APPROX_TOP_SUM for flexibility
  APPROX_TOP_SUM(statement_type, 1, 30) AS statement_types,
  -- Performance metrics
  AVG(total_time_seconds) AS avg_duration_seconds,
  PERCENTILE_CONT(total_time_seconds, 0.5) AS median_duration_seconds
FROM {{ jobs_done_incremental_hourly() }}
GROUP BY ALL
