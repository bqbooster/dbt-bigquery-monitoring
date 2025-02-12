{{
   config(
    materialized='view',
    )
}}
SELECT
  *,
  ondemand_query_cost - flat_pricing_query_cost AS cost_savings,
  1 - SAFE_DIVIDE(ondemand_query_cost, flat_pricing_query_cost) AS cost_savings_pct
FROM
  {{ ref('jobs_by_project_with_cost') }}
WHERE
  ondemand_query_cost > flat_pricing_query_cost
  AND flat_pricing_query_cost > 0
