{{
   config(
    materialized='view',
    )
}}
SELECT
  *,
  flat_pricing_query_cost - ondemand_query_cost AS cost_savings,
  1 - ondemand_query_cost / flat_pricing_query_cost AS cost_savings_pct
FROM
  {{ ref('jobs_by_project_with_cost') }}
WHERE
ondemand_query_cost <= flat_pricing_query_cost
