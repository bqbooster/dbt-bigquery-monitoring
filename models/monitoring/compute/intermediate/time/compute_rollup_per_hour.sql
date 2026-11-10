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
  Additive metrics still come from the minute rollup. Percentiles cannot be
  summed from per-minute sketches, so they are APPROX_QUANTILES over the jobs
  in the hour. That scan lists scalar columns only (no query text or job_stages)
  and is limited to the hour partitions this run rewrites.
-#}
WITH minute_rows AS (
  SELECT *
  FROM {{ ref("compute_rollup_per_minute") }}
  {% if is_incremental() %}
  WHERE minute >= {{ get_partition_timestamp() }}
  {% endif %}
),

rolled AS (
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
    STRUCT(
      SUM(job_state.done) AS done,
      SUM(job_state.running) AS running,
      SUM(job_state.pending) AS pending
    ) AS job_state,
    ARRAY_AGG(
      STRUCT(
        jt.value,
        jt.sum
      ) IGNORE NULLS
    ) AS job_types,
    ARRAY_AGG(
      STRUCT(
        st.value,
        st.sum
      ) IGNORE NULLS
    ) AS statement_types,
    AVG(avg_duration_seconds) AS avg_duration_seconds,
    AVG(median_duration_seconds) AS median_duration_seconds
  FROM minute_rows
  LEFT JOIN UNNEST(job_types) AS jt
  LEFT JOIN UNNEST(statement_types) AS st
  GROUP BY ALL
),

job_quantiles AS (
  SELECT
    TIMESTAMP_TRUNC(creation_time, HOUR) AS hour,
    project_id,
    reservation_id,
    bi_engine_statistics.bi_engine_mode AS bi_engine_mode,
    client_type,
    edition,
    AVG({{ queue_wait_ms() }}) AS avg_queue_wait_ms,
    APPROX_QUANTILES(total_time_seconds, 100) AS duration_quantiles,
    APPROX_QUANTILES({{ queue_wait_ms() }}, 100) AS queue_wait_quantiles
  FROM {{ ref('jobs_with_cost') }}
  WHERE creation_time >= {{ get_partition_logic() }}
    {% if dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() %}
    AND hour >= TIMESTAMP_SUB(
      TIMESTAMP_TRUNC({{ get_partition_logic() }}, HOUR),
      INTERVAL 6 HOUR
    )
    {% endif %}
    AND state = 'DONE'
  GROUP BY ALL
)

SELECT
  rolled.hour,
  rolled.project_id,
  rolled.reservation_id,
  rolled.bi_engine_mode,
  rolled.client_type,
  rolled.edition,
  rolled.total_query_cost,
  rolled.failing_query_cost,
  rolled.total_bytes_processed,
  rolled.total_bytes_billed,
  rolled.total_slot_ms,
  rolled.query_count,
  rolled.unique_users,
  rolled.unique_sessions,
  rolled.cache_hits,
  rolled.job_state,
  rolled.job_types,
  rolled.statement_types,
  rolled.avg_duration_seconds,
  rolled.median_duration_seconds,
  job_quantiles.avg_queue_wait_ms,
  job_quantiles.duration_quantiles[SAFE_OFFSET(50)] AS duration_p50_seconds,
  job_quantiles.duration_quantiles[SAFE_OFFSET(90)] AS duration_p90_seconds,
  job_quantiles.duration_quantiles[SAFE_OFFSET(99)] AS duration_p99_seconds,
  job_quantiles.queue_wait_quantiles[SAFE_OFFSET(50)] AS queue_wait_p50_ms,
  job_quantiles.queue_wait_quantiles[SAFE_OFFSET(90)] AS queue_wait_p90_ms,
  job_quantiles.queue_wait_quantiles[SAFE_OFFSET(99)] AS queue_wait_p99_ms
FROM rolled
LEFT JOIN job_quantiles
  ON rolled.hour = job_quantiles.hour
  AND rolled.project_id IS NOT DISTINCT FROM job_quantiles.project_id
  AND rolled.reservation_id IS NOT DISTINCT FROM job_quantiles.reservation_id
  AND rolled.bi_engine_mode IS NOT DISTINCT FROM job_quantiles.bi_engine_mode
  AND rolled.client_type IS NOT DISTINCT FROM job_quantiles.client_type
  AND rolled.edition IS NOT DISTINCT FROM job_quantiles.edition
