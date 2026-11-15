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
    cluster_by = ["project_id", "reservation_id"],
    partition_expiration_days = dbt_bigquery_monitoring_variable_lookback_window_days()
    )
}}
{#-
  Reads jobs_with_cost (not INFORMATION_SCHEMA directly) for the incremental
  window only. The select list touches performance-insight leaves and the
  shuffle byte fields, not query text, timeline, or the rest of job_stages.
-#}
{% set insight_ns = namespace(columns='') %}
{% if information_schema_job_columns_available() %}
    {% set insight_body %}
  hour,
  project_id,
  reservation_id,
  job_id,
  user_email,
  total_slot_ms,
  {{ shuffle_spill_sql('job_stages') }} AS spill,
  {{ performance_insight_flags('query_info.performance_insights.stage_performance_standalone_insights') }} AS flags,
  query_info.performance_insights.avg_previous_execution_ms AS avg_previous_execution_ms
    {% endset %}
    {% set insight_ns.columns = insight_body %}
{% else %}
    {% set insight_body %}
  hour,
  project_id,
  reservation_id,
  job_id,
  user_email,
  total_slot_ms,
  STRUCT(
    CAST(NULL AS INT64) AS shuffle_output_bytes,
    CAST(NULL AS INT64) AS shuffle_output_bytes_spilled
  ) AS spill,
  STRUCT(
    FALSE AS has_slot_contention,
    0 AS slot_contention_stage_count,
    FALSE AS has_insufficient_shuffle_quota,
    0 AS insufficient_shuffle_quota_stage_count,
    FALSE AS has_partition_skew,
    0 AS partition_skew_stage_count,
    FALSE AS has_high_cardinality_join,
    0 AS high_cardinality_join_count
  ) AS flags,
  CAST(NULL AS INT64) AS avg_previous_execution_ms
    {% endset %}
    {% set insight_ns.columns = insight_body %}
{% endif %}

SELECT
  hour,
  project_id,
  reservation_id,
  job_id,
  user_email,
  total_slot_ms,
  spill.shuffle_output_bytes,
  spill.shuffle_output_bytes_spilled,
  flags.has_slot_contention,
  flags.slot_contention_stage_count,
  flags.has_insufficient_shuffle_quota,
  flags.insufficient_shuffle_quota_stage_count,
  flags.has_partition_skew,
  flags.partition_skew_stage_count,
  flags.has_high_cardinality_join,
  flags.high_cardinality_join_count,
  avg_previous_execution_ms
FROM {{ jobs_done_incremental_hourly(insight_ns.columns) }}
