{{
   config(
    materialized='table',
    )
}}
WITH last_used_date AS (
  SELECT
    project_id,
    dataset_id,
    table_id,
    MAX(day) AS last_used_date
  FROM {{ ref('table_reference_incremental') }} AS ut
  GROUP BY ALL
)
SELECT
 ts.*,
 last_used_date
FROM {{ ref('table_and_storage_with_cost') }} AS ts
LEFT JOIN last_used_date USING (project_id, dataset_id, table_id)
