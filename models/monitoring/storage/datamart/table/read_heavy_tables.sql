{{
   config(
    materialized='view',
    )
}}

WITH table_reference AS (
  SELECT
project_id,
dataset_id,
table_id,
SUM(reference_count) AS reference_count
  FROM {{ ref('table_reference_incremental') }}
  WHERE day > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
  GROUP BY ALL
)

SELECT
 ts.*,
 trc.reference_count
FROM {{ ref('storage_with_cost') }} AS ts
INNER JOIN table_reference AS trc USING (project_id, dataset_id, table_id)
ORDER BY trc.reference_count DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
