{{
   config(
    materialized='incremental',
    incremental_strategy = 'merge',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "day",
      "data_type": "timestamp"
    },
    cluster_by = ["hour"],
    unique_key = ['hour']
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  TIMESTAMP_TRUNC(creation_time, DAY) AS day,
  TIMESTAMP_TRUNC(creation_time, HOUR) AS hour,
  SUM(query_cost) AS total_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  COUNT(*) AS query_count
FROM {{ ref('jobs_by_project_with_cost') }}
{% if is_incremental() %}
  where creation_time >= date_sub(date(_dbt_max_partition), interval 1 day)
{% endif %}
GROUP BY day, hour
