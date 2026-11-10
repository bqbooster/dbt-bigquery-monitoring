{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "minute",
      "granularity": "hour",
      "data_type": "timestamp",
      "copy_partitions": dbt_bigquery_monitoring_variable_use_copy_partitions()
    },
    cluster_by = ['minute', 'project_id'],
    partition_expiration_days = dbt_bigquery_monitoring_variable_output_partition_expiration_days()
    )
}}
WITH jobs AS (
  SELECT
    TIMESTAMP_TRUNC(creation_time, MINUTE) AS minute,
    project_id,
    reservation_id,
    bi_engine_statistics.bi_engine_mode AS bi_engine_mode,
    client_type,
    edition,
    query_cost,
    error_result,
    total_bytes_processed,
    total_bytes_billed,
    total_slot_ms,
    user_email,
    session_info.session_id AS session_id,
    cache_hit,
    state,
    job_type,
    statement_type,
    total_time_seconds,
    {{ queue_wait_ms() }} AS queue_wait_ms
  FROM {{ jobs_done_incremental_hourly() }}
),

aggregated AS (
  SELECT
    minute,
    project_id,
    reservation_id,
    bi_engine_mode,
    client_type,
    edition,
    SUM(ROUND(query_cost, 2)) AS total_query_cost,
    SUM(IF(error_result IS NOT NULL, ROUND(query_cost, 2), 0)) AS failing_query_cost,
    SUM(total_bytes_processed) AS total_bytes_processed,
    SUM(total_bytes_billed) AS total_bytes_billed,
    SUM(total_slot_ms) AS total_slot_ms,
    COUNT(*) AS query_count,
    COUNT(DISTINCT user_email) AS unique_users,
    COUNT(DISTINCT session_id) AS unique_sessions,
    COUNTIF(cache_hit) AS cache_hits,
    STRUCT(
      COUNTIF(state = 'DONE') AS done,
      COUNTIF(state = 'RUNNING') AS running,
      COUNTIF(state = 'PENDING') AS pending
    ) AS job_state,
    APPROX_TOP_SUM(job_type, 1, 20) AS job_types,
    APPROX_TOP_SUM(statement_type, 1, 30) AS statement_types,
    AVG(total_time_seconds) AS avg_duration_seconds,
    AVG(queue_wait_ms) AS avg_queue_wait_ms,
    -- One sketch per metric, then read p50/p90/p99 from it.
    APPROX_QUANTILES(total_time_seconds, 100) AS duration_quantiles,
    APPROX_QUANTILES(queue_wait_ms, 100) AS queue_wait_quantiles
  FROM jobs
  GROUP BY ALL
)

SELECT
  * EXCEPT (duration_quantiles, queue_wait_quantiles),
  duration_quantiles[SAFE_OFFSET(50)] AS median_duration_seconds,
  duration_quantiles[SAFE_OFFSET(50)] AS duration_p50_seconds,
  duration_quantiles[SAFE_OFFSET(90)] AS duration_p90_seconds,
  duration_quantiles[SAFE_OFFSET(99)] AS duration_p99_seconds,
  queue_wait_quantiles[SAFE_OFFSET(50)] AS queue_wait_p50_ms,
  queue_wait_quantiles[SAFE_OFFSET(90)] AS queue_wait_p90_ms,
  queue_wait_quantiles[SAFE_OFFSET(99)] AS queue_wait_p99_ms
FROM aggregated
