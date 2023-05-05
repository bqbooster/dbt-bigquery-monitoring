{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  *,
  milliseconds_to_readable_time_udf(total_slot_ms, 2) AS total_slot_time
FROM {{ ref('jobs_by_project_with_cost') }}
ORDER BY creation_time DESC
LIMIT {{ var('output_limit_size') }}
