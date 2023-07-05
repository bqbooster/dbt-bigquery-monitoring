{{
   config(
    materialized='table',
    )
}}
WITH table_reference_count AS (
  SELECT
rt.project_id,
rt.dataset_id,
rt.table_id,
count(*) AS reference_count
  FROM {{ ref('jobs_by_project_with_cost') }}, unnest(referenced_tables) AS rt
  GROUP BY 1, 2, 3
)

SELECT
 ts.*,
 trc.reference_count
FROM {{ ref('table_and_storage_with_cost') }} AS ts
INNER JOIN table_reference_count AS trc USING (project_id, dataset_id, table_id)
ORDER BY trc.reference_count DESC
LIMIT {{ var('output_limit_size') }}
