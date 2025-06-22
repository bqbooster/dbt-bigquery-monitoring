{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "hour",
      "granularity": "day",
      "data_type": "timestamp",
      "copy_partitions": should_use_copy_partitions()
    },
    cluster_by = ['hour', 'project_id'],
    partition_expiration_days = var('output_partition_expiration_days')
    )
}}
SELECT
  TIMESTAMP_TRUNC(minute, HOUR) AS hour,
  project_id,
  reservation_id,
  bi_engine_mode,
  client_type,
  edition,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(ROUND(failing_query_cost, 2)) AS failing_query_cost,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SUM(total_bytes_billed) AS total_bytes_billed,
  SUM(total_slot_ms) AS total_slot_ms,
  SUM(query_count) AS query_count,
  SUM(unique_users) AS unique_users,
  SUM(unique_sessions) AS unique_sessions,
  SUM(cache_hits) AS cache_hits,
  -- Job state breakdown
  STRUCT(
    SUM(job_state.done) AS done,
    SUM(job_state.running) AS running,
    SUM(job_state.pending) AS pending
  ) AS job_state,
  -- Job type breakdown - aggregate arrays properly
  ARRAY_AGG(STRUCT(job_types.value, job_types.count) IGNORE NULLS) AS job_types,
  -- Statement type breakdown - aggregate arrays properly
  ARRAY_AGG(STRUCT(statement_types.value, statement_types.count) IGNORE NULLS) AS statement_types,
  -- Performance metrics
  AVG(avg_duration_seconds) AS avg_duration_seconds,
  AVG(median_duration_seconds) AS median_duration_seconds
FROM {{ ref("compute_rollup_per_minute") }}
GROUP BY ALL
