{{
   config(
    materialized='table',
    )
}}
SELECT
  ts.*,
  trc.*
FROM {{ ref('table_and_storage_with_cost') }} AS ts
INNER JOIN table_reference_count AS trc USING (project_id, dataset_id, table_id)
ORDER BY trc.reference_count DESC
LIMIT {{ var('output_limit_size') }}
