{{
   config(
    materialized='view',
    )
}}
{#
  Detects tables that have been written to recently but have never been read (or not read within the lookback window).
  These "write-only" tables often represent pipeline outputs that are no longer consumed — candidates for archival or deletion.
#}
WITH last_read AS (
  SELECT
    project_id,
    dataset_id,
    table_id,
    MAX(day) AS last_read_date,
    SUM(reference_count) AS total_reference_count
  FROM {{ ref('table_reference_incremental') }}
  GROUP BY project_id, dataset_id, table_id
)

SELECT
  s.project_id,
  s.dataset_id,
  s.table_id,
  s.table_type,
  s.storage_last_modified_time,
  r.last_read_date,
  COALESCE(r.total_reference_count, 0) AS total_reference_count,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), s.storage_last_modified_time, DAY) AS days_since_last_write,
  CASE
    WHEN r.last_read_date IS NULL THEN 'Never read'
    ELSE CAST(TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), CAST(r.last_read_date AS TIMESTAMP), DAY) AS STRING) || ' days ago'
  END AS last_read_label,
  s.cost_monthly_forecast,
  s.total_logical_bytes,
  s.total_physical_bytes,
  s.total_rows,
  s.total_partitions,
  s.storage_billing_model
FROM {{ ref('storage_with_cost') }} AS s
LEFT JOIN last_read AS r USING (project_id, dataset_id, table_id)
WHERE
  -- Table has been modified recently (it's active / being written to)
  s.storage_last_modified_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
  -- But has never been read OR was last read before the lookback window
  AND (
    r.last_read_date IS NULL
    OR CAST(r.last_read_date AS TIMESTAMP) < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
  )
  AND s.table_type = 'BASE TABLE'
ORDER BY s.cost_monthly_forecast DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
