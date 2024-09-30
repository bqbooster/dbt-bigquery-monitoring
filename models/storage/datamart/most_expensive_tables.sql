{{
   config(
    materialized='table',
    )
}}
SELECT *
FROM {{ ref('table_and_storage_with_cost') }}
{%- if var('prefer_physical_pricing_model') %}
ORDER BY physical_cost_monthly_forecast DESC
{%- else %}
ORDER BY logical_cost_monthly_forecast DESC
{%- endif %}
LIMIT {{ var('output_limit_size') }}
