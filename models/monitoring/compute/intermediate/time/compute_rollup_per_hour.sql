{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "hour",
      "granularity": "day",
      "data_type": "timestamp",
      "copy_partitions": dbt_bigquery_monitoring_variable_use_copy_partitions()
    },
    cluster_by = ['hour', 'project_id'],
    partition_expiration_days = dbt_bigquery_monitoring_variable_output_partition_expiration_days()
    )
}}
{#-
  Existing metrics are unchanged and still come from every minute row.
  New percentile columns are query-count-weighted averages of the minute
  APPROX_QUANTILES. A true hour sketch would scan JOBS again for the whole
  retention window; the unnest fanout cancels out of the weighted ratio.
-#}
SELECT
  TIMESTAMP_TRUNC(MINUTE, HOUR) AS hour,
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
  -- Job type breakdown - aggregate arrays properly by collecting all values
  ARRAY_AGG(
    STRUCT(
      jt.value,
      jt.sum
    ) IGNORE NULLS
  ) AS job_types,
  -- Statement type breakdown - aggregate arrays properly by collecting all values
  ARRAY_AGG(
    STRUCT(
      st.value,
      st.sum
    ) IGNORE NULLS
  ) AS statement_types,
  -- Performance metrics
  AVG(avg_duration_seconds) AS avg_duration_seconds,
  AVG(median_duration_seconds) AS median_duration_seconds,
  SAFE_DIVIDE(SUM(avg_queue_wait_ms * query_count), SUM(query_count)) AS avg_queue_wait_ms,
  SAFE_DIVIDE(SUM(duration_p50_seconds * query_count), SUM(query_count)) AS duration_p50_seconds,
  SAFE_DIVIDE(SUM(duration_p90_seconds * query_count), SUM(query_count)) AS duration_p90_seconds,
  SAFE_DIVIDE(SUM(duration_p99_seconds * query_count), SUM(query_count)) AS duration_p99_seconds,
  SAFE_DIVIDE(SUM(queue_wait_p50_ms * query_count), SUM(query_count)) AS queue_wait_p50_ms,
  SAFE_DIVIDE(SUM(queue_wait_p90_ms * query_count), SUM(query_count)) AS queue_wait_p90_ms,
  SAFE_DIVIDE(SUM(queue_wait_p99_ms * query_count), SUM(query_count)) AS queue_wait_p99_ms
FROM {{ ref("compute_rollup_per_minute") }}
LEFT JOIN UNNEST(job_types) AS jt
LEFT JOIN UNNEST(statement_types) AS st
GROUP BY ALL
