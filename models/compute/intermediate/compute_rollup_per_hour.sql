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
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  TIMESTAMP_TRUNC(MINUTE, HOUR) AS hour,
  project_id,
  reservation_id,
  bi_engine_mode,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(ROUND(failing_query_cost, 2)) AS failing_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(total_slot_ms, 2) AS total_slot_time,
  SUM(query_count) AS query_count,
  STRUCT(
    SUM(job_state.done) AS done,
    SUM(job_state.running) AS running,
    SUM(job_state.pending) AS pending
  ) AS job_state
FROM {{ ref("compute_rollup_per_minute") }}
GROUP BY ALL
