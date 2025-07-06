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
WHERE j.rank_cost <= {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
ORDER BY query_cost DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
