{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "minute",
      "granularity": "hour",
      "data_type": "timestamp",
      "copy_partitions": should_use_copy_partitions()
    },
    cluster_by = ['minute', 'project_id'],
    partition_expiration_days = var('output_partition_expiration_days')
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  TIMESTAMP_TRUNC(creation_time, MINUTE) AS minute,
  project_id,
  reservation_id,
  SUM(ROUND(query_cost, 2)) AS total_query_cost,
  SUM(IF(error_result IS NOT NULL, ROUND(query_cost, 2), 0)) AS failing_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(total_slot_ms, 2) AS total_slot_time,
  COUNT(*) AS query_count,
  STRUCT(
    COUNTIF(state = 'DONE') AS done,
    COUNTIF(state = 'RUNNING') AS running,
    COUNTIF(state = 'PENDING') AS pending
  ) AS job_state
FROM {{ jobs_done_incremental_minute() }}
GROUP BY ALL
