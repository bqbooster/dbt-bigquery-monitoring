{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by = {
      "field": "hour",
      "data_type": "timestamp",
      "granularity": "hour",
      "copy_partitions": dbt_bigquery_monitoring_variable_use_copy_partitions()
    },
    cluster_by = ["hour", "query"],
    partition_expiration_days = dbt_bigquery_monitoring_variable_lookback_window_days()
    )
}}

WITH base AS (
  SELECT
  hour,
  project_id,
  reservation_id,
  job_id,
  query,
  {{ query_fingerprint_sql(normalized_literals_sql(), 'query') }} AS query_fingerprint,
  {{ normalized_literals_sql() }} AS normalized_query_hash,
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
  {% if dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_group_repeated_jobs_by_normalized_hash() %}
  -- Example statement for this fingerprint. The jobs array does not repeat query text.
  APPROX_TOP_COUNT(query, 1)[SAFE_OFFSET(0)].value AS query,
  {% else %}
  query,
  {% endif %}
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
  AVG(total_time_seconds) AS avg_duration_seconds,
  {% if dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_group_repeated_jobs_by_normalized_hash() %}
  query_fingerprint,
  ANY_VALUE(normalized_query_hash) AS normalized_query_hash
  {% else %}
  COALESCE(MAX(normalized_query_hash), query) AS query_fingerprint,
  MAX(normalized_query_hash) AS normalized_query_hash
  {% endif %}
FROM base
GROUP BY {{ repeated_jobs_group_key() }}
