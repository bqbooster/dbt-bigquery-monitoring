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
WHERE j.rank_cost <= {{ var('output_limit_size') }}
ORDER BY query_cost DESC
LIMIT {{ var('output_limit_size') }}
