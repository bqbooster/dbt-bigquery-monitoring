{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    cluster_by = ["user_email"],
    partition_by = {
      "field": "day",
      "data_type": "timestamp"
    },
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  TIMESTAMP_TRUNC(creation_time, DAY) day,
  user_email,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  COUNT(*) AS query_count
FROM {{ ref('jobs_incremental') }}
GROUP BY day, user_email
