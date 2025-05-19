{{
   config(
    materialized='view',
    )
}}
WITH base AS (
SELECT
  project_id,
  dataset_id,
  storage_billing_model,
  optimal_storage_billing_model,
  SUM(total_logical_tb) AS total_logical_tb,
  SUM(total_physical_tb) AS total_physical_tb,
  SUM(logical_cost_monthly_forecast) AS logical_cost_monthly_forecast,
  SUM(physical_cost_monthly_forecast) AS physical_cost_monthly_forecast,
  SUM(storage_pricing_model_difference) AS storage_pricing_model_difference,
  SUM(
    IF(optimal_storage_billing_model = "LOGICAL",
       potential_savings,
    NULL)
  ) AS logical_part_potential_savings,
  SUM(
    IF(optimal_storage_billing_model = "PHYSICAL",
       potential_savings,
    NULL)
  ) AS physical_part_potential_savings,
  SUM(potential_savings) AS maximum_potential_savings
FROM {{ ref('storage_with_cost') }}
WHERE
table_type = "BASE TABLE"
AND potential_savings > 0
GROUP BY ALL
),

with_optimal AS (
  SELECT
  * EXCEPT (optimal_storage_billing_model),
  IF(logical_cost_monthly_forecast > physical_cost_monthly_forecast, "PHYSICAL", "LOGICAL") AS optimal_storage_billing_model,
  FROM base
)

SELECT
  *,
  IF(storage_billing_model != optimal_storage_billing_model, storage_pricing_model_difference, NULL) AS potential_savings
FROM with_optimal
ORDER BY potential_savings DESC
LIMIT {{ var('output_limit_size') }}
