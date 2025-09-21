{{
   config(
    materialized='view',
    )
}}
SELECT
  *,
  flat_pricing_query_cost - ondemand_query_cost AS cost_savings,
  1 - SAFE_DIVIDE(flat_pricing_query_cost, ondemand_query_cost) AS cost_savings_pct
FROM
  {{ ref('jobs_with_cost') }}
WHERE
  flat_pricing_query_cost > ondemand_query_cost
  AND ondemand_query_cost > 0
