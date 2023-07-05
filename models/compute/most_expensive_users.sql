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
  day,
  user_email,
  SUM(query_cost)/SUM(query_count) AS avg_query_cost,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  SUM(query_count) AS query_count
FROM {{ ref('most_expensive_users_incremental') }}
GROUP BY user_email
ORDER BY total_query_cost DESC
LIMIT {{ var('output_limit_size') }}
