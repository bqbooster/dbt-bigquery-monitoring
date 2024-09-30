{{
   config(
    materialized='table',
    )
}}
WITH storage_cost AS (
  SELECT
    project_id,
    dataset_id,
    table_id,
    total_logical_tb,
    total_physical_tb,
    logical_cost_monthly_forecast,
    physical_cost_monthly_forecast,
    storage_pricing_model_difference
  FROM {{ ref('table_and_storage_with_cost') }}
  WHERE total_physical_bytes > 0
  AND table_type = 'BASE TABLE'
  AND NOT prefer_physical_pricing_model
)

SELECT *
FROM storage_cost
ORDER BY storage_pricing_model_difference DESC
LIMIT {{ var('output_limit_size') }}
