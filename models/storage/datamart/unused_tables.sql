{{
   config(
    materialized='table',
    )
}}
SELECT
 ts.*
FROM {{ ref('table_and_storage_with_cost') }} AS ts
LEFT JOIN {{ ref('table_reference_incremental') }} AS ut USING (project_id, dataset_id, table_id)
WHERE ut.table_id IS NULL
