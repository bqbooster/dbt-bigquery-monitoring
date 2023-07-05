{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    cluster_by = ["query"],
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
  query,
  APPROX_TOP_COUNT(project_id, 100) AS project_ids,
  APPROX_TOP_COUNT(reservation_id, 100) AS reservation_ids,
  APPROX_TOP_COUNT(user_email, 100) AS user_emails,
  COUNTIF(cache_hit) / COUNT(*) AS cache_hit_ratio,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  COUNT(*) AS amount
FROM
  {{ ref('jobs_incremental') }}
GROUP BY query
