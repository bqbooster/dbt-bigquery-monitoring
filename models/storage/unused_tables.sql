{{
   config(
    materialized='table',
    )
}}
WITH used_tables AS (
  SELECT
rt.project_id,
rt.dataset_id,
rt.table_id
  FROM {{ ref('jobs_by_project_with_cost') }}, UNNEST(referenced_tables) AS rt
  GROUP BY 1, 2, 3
)

SELECT
 ts.*
FROM {{ ref('table_and_storage_with_cost') }} AS ts
LEFT JOIN used_tables AS ut USING (project_id, dataset_id, table_id)
WHERE ut.table_id IS NULL
