{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}

WITH new_jobs AS (
select
  TIMESTAMP_TRUNC(creation_time, HOUR) AS hour,
  job_id,
  query_cost,
  total_slot_ms,
  milliseconds_to_readable_time_udf(total_slot_ms, 2) AS total_slot_time
FROM {{ ref('jobs_incremental') }}
),
{% if is_incremental_run() %}
current_jobs AS (
  SELECT hour,
  job_id,
  query_cost,
  total_slot_ms,
  total_slot_time
  FROM {{ this }}
  WHERE hour > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ var('lookback_window_days') }} DAY)
),
{% endif %}
all_jobs AS (
  SELECT *
  FROM new_jobs
  {% if is_incremental_run() %}
  UNION ALL
  SELECT *
  FROM current_jobs
  {% endif %}
)

SELECT *
FROM all_jobs
ORDER BY query_cost DESC
LIMIT {{ var('output_limit_size') }}
