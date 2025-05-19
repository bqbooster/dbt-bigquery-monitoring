{{
   config(
    materialized='view',
    )
}}
SELECT
  hour,
query,
j.*
FROM {{ ref('jobs_costs_incremental') }}, UNNEST(jobs) AS j
WHERE j.rank_duration <= {{ var('output_limit_size') }}
ORDER BY total_time_seconds DESC
LIMIT {{ var('output_limit_size') }}
