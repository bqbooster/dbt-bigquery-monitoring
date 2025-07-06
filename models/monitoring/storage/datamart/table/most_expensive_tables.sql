{{
   config(
    materialized='view',
    )
}}
SELECT *
FROM {{ ref('storage_with_cost') }}
ORDER BY cost_monthly_forecast DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
