{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "day",
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
WITH new_data AS (
  SELECT
    TIMESTAMP_TRUNC(creation_time, DAY) AS day,
    TIMESTAMP_TRUNC(creation_time, HOUR) AS hour,
    project_id,
    SUM(ROUND(query_cost, 2)) AS total_query_cost,
    SUM(IF(error_result IS NOT NULL, ROUND(query_cost, 2), 0)) AS failing_query_cost,
    SUM(total_slot_ms) AS total_slot_ms,
    MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
    COUNT(*) AS query_count
  FROM {{ ref('jobs_incremental') }}
  {% if is_incremental() %}
  WHERE TIMESTAMP_TRUNC(creation_time, DAY) >= _dbt_max_partition
  {% endif %}
  GROUP BY day, hour, project_id
)
{% if is_incremental() %}
,
last_partition_data_if_existing AS (
  SELECT
day,
hour,
project_id,
total_query_cost,
failing_query_cost,
total_slot_ms,
query_count
  FROM {{ this }}
  WHERE day = TIMESTAMP_TRUNC(_dbt_max_partition, DAY)
)

SELECT
  day,
  hour,
  project_id,
  SUM(total_query_cost) AS total_query_cost,
  SUM(failing_query_cost) AS failing_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  MILLISECONDS_TO_READABLE_TIME_UDF(SUM(total_slot_ms), 2) AS total_slot_time,
  SUM(query_count) AS query_count
FROM (
  SELECT
l.day,
l.hour,
l.project_id,
l.total_query_cost,
l.failing_query_cost,
l.total_slot_ms,
l.query_count
FROM last_partition_data_if_existing AS l
  UNION ALL
  SELECT
n.day,
n.hour,
n.project_id,
n.total_query_cost,
n.failing_query_cost,
n.total_slot_ms,
n.query_count
FROM new_data AS n
)
GROUP BY day, hour, project_id
{% else %}
SELECT * FROM new_data
{% endif %}
