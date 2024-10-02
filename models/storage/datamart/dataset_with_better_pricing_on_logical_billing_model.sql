{{
   config(
    materialized='table',
    )
}}
WITH storage_cost AS (
  SELECT
    project_id,
    dataset_id,
    SUM(total_logical_tb) AS total_logical_tb,
    SUM(total_physical_tb) AS total_physical_tb,
    SUM(logical_cost_monthly_forecast) AS logical_cost_monthly_forecast,
    SUM(physical_cost_monthly_forecast) AS physical_cost_monthly_forecast,
    SUM(storage_pricing_model_difference) AS storage_pricing_model_difference
  FROM {{ ref('table_and_storage_with_cost') }}
  WHERE total_physical_bytes > 0
  AND table_type = 'BASE TABLE'
  AND NOT prefer_physical_pricing_model
  GROUP BY ALL
)

SELECT *
FROM storage_cost
ORDER BY storage_pricing_model_difference DESC
LIMIT {{ var('output_limit_size') }}
