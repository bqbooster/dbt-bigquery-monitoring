{{
   config(
    materialized='table',
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  * EXCEPT (total_time_seconds, rank),
  milliseconds_to_readable_time_udf(total_time_seconds * 1000, 2) AS total_run_time
FROM {{ ref('slowest_jobs_incremental') }}
WHERE total_time_seconds IS NOT NULL
ORDER BY total_time_seconds DESC
LIMIT {{ var('output_limit_size') }}
