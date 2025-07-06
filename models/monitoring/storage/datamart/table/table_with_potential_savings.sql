{{
   config(
    materialized='view',
    )
}}
SELECT
  project_id,
  dataset_id,
  table_id,
  total_logical_tb,
  total_physical_tb,
  logical_cost_monthly_forecast,
  physical_cost_monthly_forecast,
  optimal_storage_billing_model,
  potential_savings
FROM {{ ref('storage_with_cost') }}
WHERE
table_type = 'BASE TABLE'
AND potential_savings > 0
ORDER BY storage_pricing_model_difference DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
