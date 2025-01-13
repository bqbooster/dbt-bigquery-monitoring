{{
   config(
    materialized='view',
    )
}}
SELECT *
FROM {{ ref('compute_rollup_per_minute') }}
