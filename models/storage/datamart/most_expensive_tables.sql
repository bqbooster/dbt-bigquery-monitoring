{{
   config(
    materialized='table',
    )
}}
SELECT
  *
FROM {{ ref('table_and_storage_with_cost') }}
ORDER BY storage_cost DESC
LIMIT {{ var('output_limit_size') }}
