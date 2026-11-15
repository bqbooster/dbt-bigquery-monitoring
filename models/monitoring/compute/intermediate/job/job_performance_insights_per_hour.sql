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
  Rolls up job_performance_insights. This model does not read JOBS again.
  Every done job is included so slot-time ratios use the full denominator.
-#}
SELECT
  hour,
  project_id,
  reservation_id,
  COUNT(*) AS job_count,
  SUM(total_slot_ms) AS total_slot_ms,
  COUNTIF(has_slot_contention) AS slot_contention_jobs,
  SUM(IF(has_slot_contention, total_slot_ms, 0)) AS slot_contention_slot_ms,
  SAFE_DIVIDE(SUM(IF(has_slot_contention, total_slot_ms, 0)), SUM(total_slot_ms)) AS slot_contention_slot_ms_ratio,
  COUNTIF(has_insufficient_shuffle_quota) AS insufficient_shuffle_quota_jobs,
  SUM(IF(has_insufficient_shuffle_quota, total_slot_ms, 0)) AS insufficient_shuffle_quota_slot_ms,
  SAFE_DIVIDE(
    SUM(IF(has_insufficient_shuffle_quota, total_slot_ms, 0)),
    SUM(total_slot_ms)
  ) AS insufficient_shuffle_quota_slot_ms_ratio,
  COUNTIF(has_partition_skew) AS partition_skew_jobs,
  SUM(IF(has_partition_skew, total_slot_ms, 0)) AS partition_skew_slot_ms,
  SAFE_DIVIDE(SUM(IF(has_partition_skew, total_slot_ms, 0)), SUM(total_slot_ms)) AS partition_skew_slot_ms_ratio,
  COUNTIF(has_high_cardinality_join) AS high_cardinality_join_jobs,
  SUM(IF(has_high_cardinality_join, total_slot_ms, 0)) AS high_cardinality_join_slot_ms,
  SAFE_DIVIDE(
    SUM(IF(has_high_cardinality_join, total_slot_ms, 0)),
    SUM(total_slot_ms)
  ) AS high_cardinality_join_slot_ms_ratio,
  SUM(shuffle_output_bytes) AS shuffle_output_bytes,
  SUM(shuffle_output_bytes_spilled) AS shuffle_output_bytes_spilled,
  COUNTIF(shuffle_output_bytes_spilled > 0) AS jobs_with_shuffle_spill
FROM {{ ref('job_performance_insights') }}
WHERE hour >= {{ get_partition_logic() }}
GROUP BY hour, project_id, reservation_id
