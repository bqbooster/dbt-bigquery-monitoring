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
SELECT
  minute,
  project_id,
  reservation_id,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(ROUND(failing_query_cost, 2)) AS failing_query_cost,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SUM(total_bytes_billed) AS total_bytes_billed,
  SUM(total_slot_ms) AS total_slot_ms,
  SUM(query_count) AS query_count,
  SUM(unique_users) AS unique_users,
  SUM(unique_sessions) AS unique_sessions,
  SUM(cache_hits) AS cache_hits,
  AVG(avg_duration_seconds) AS avg_duration_seconds,
  STRUCT(
    SUM(job_state.done) AS done,
    SUM(job_state.running) AS running,
    SUM(job_state.pending) AS pending
  ) AS job_state
FROM {{ ref('compute_rollup_per_minute') }}
GROUP BY ALL
