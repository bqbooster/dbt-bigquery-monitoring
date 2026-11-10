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
-- Sum metrics and repeated arrays in one grouped pass, then derive
-- distinct counts from the concatenated arrays. Two UNNEST joins in the
-- same FROM multiply every SUM by the product of the array lengths.
WITH filtered_minutes AS (
  SELECT
    minute,
    project_id,
    reservation_id,
    bi_engine_mode,
    client_type,
    edition,
    total_query_cost,
    failing_query_cost,
    total_bytes_processed,
    total_bytes_billed,
    total_slot_ms,
    query_count,
    unique_users,
    unique_sessions,
    cache_hits,
    job_state,
    avg_duration_seconds,
    median_duration_seconds,
    user_emails,
    session_ids,
    job_types,
    statement_types
  FROM {{ ref("compute_rollup_per_minute") }}
  {{ compute_incremental_minute_filter('minute') }}
),

grouped AS (
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
    -- Partitions built before user_emails / session_ids existed store NULL arrays.
    -- Summing the per-minute counts keeps those hours stable until a full refresh
    -- backfills the arrays. Exact distinct counts require every minute in the hour.
    SUM(unique_users) AS summed_unique_users,
    SUM(unique_sessions) AS summed_unique_sessions,
    LOGICAL_AND(user_emails IS NOT NULL) AS user_emails_backfilled,
    LOGICAL_AND(session_ids IS NOT NULL) AS session_ids_backfilled,
    SUM(cache_hits) AS cache_hits,
    STRUCT(
      SUM(job_state.done) AS done,
      SUM(job_state.running) AS running,
      SUM(job_state.pending) AS pending
    ) AS job_state,
    AVG(avg_duration_seconds) AS avg_duration_seconds,
    AVG(median_duration_seconds) AS median_duration_seconds,
    ARRAY_CONCAT_AGG(user_emails) AS user_emails,
    ARRAY_CONCAT_AGG(session_ids) AS session_ids,
    ARRAY_CONCAT_AGG(job_types) AS job_types,
    ARRAY_CONCAT_AGG(statement_types) AS statement_types
  FROM filtered_minutes
  GROUP BY ALL
)

SELECT
  hour,
  project_id,
  reservation_id,
  bi_engine_mode,
  client_type,
  edition,
  total_query_cost,
  failing_query_cost,
  total_bytes_processed,
  total_bytes_billed,
  total_slot_ms,
  query_count,
  IF(
    user_emails_backfilled,
    (
      SELECT COUNT(DISTINCT user_email)
      FROM UNNEST(user_emails) AS user_email
    ),
    summed_unique_users
  ) AS unique_users,
  IF(
    session_ids_backfilled,
    (
      SELECT COUNT(DISTINCT session_id)
      FROM UNNEST(session_ids) AS session_id
    ),
    summed_unique_sessions
  ) AS unique_sessions,
  cache_hits,
  job_state,
  (
    SELECT APPROX_TOP_SUM(job_type.value, job_type.sum, 20)
    FROM UNNEST(IFNULL(job_types, [])) AS job_type
    WHERE job_type.value IS NOT NULL
  ) AS job_types,
  (
    SELECT APPROX_TOP_SUM(statement_type.value, statement_type.sum, 30)
    FROM UNNEST(IFNULL(statement_types, [])) AS statement_type
    WHERE statement_type.value IS NOT NULL
  ) AS statement_types,
  avg_duration_seconds,
  median_duration_seconds
FROM grouped
