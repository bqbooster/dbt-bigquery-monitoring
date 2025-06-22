{{
   config(
    materialized='view',
    )
}}
SELECT *
FROM {{ ref('storage_with_cost') }}
ORDER BY cost_monthly_forecast DESC
LIMIT {{ var('output_limit_size') }}
