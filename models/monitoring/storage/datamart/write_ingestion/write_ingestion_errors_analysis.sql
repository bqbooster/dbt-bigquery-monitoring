{{
   config(
    materialized='view',
    )
}}
{# Analyzes error patterns for write ingestion (Streaming API + Storage Write API) by project, table and error code #}
WITH streaming_errors AS (
  SELECT
    TIMESTAMP_TRUNC(start_timestamp, DAY) AS day,
    project_id,
    dataset_id,
    table_id,
    'streaming' AS source_type,
    error_code,
    SUM(total_requests) AS total_requests,
    SUM(total_rows) AS total_rows
  FROM {{ ref('information_schema_streaming_timeline') }}
  WHERE start_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
    AND error_code IS NOT NULL
    AND error_code != ''
  GROUP BY ALL
),

write_api_errors AS (
  SELECT
    TIMESTAMP_TRUNC(start_timestamp, DAY) AS day,
    project_id,
    dataset_id,
    table_id,
    'write_api' AS source_type,
    error_code,
    SUM(total_requests) AS total_requests,
    SUM(total_rows) AS total_rows
  FROM {{ ref('information_schema_write_api_timeline') }}
  WHERE start_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
    AND error_code IS NOT NULL
    AND error_code != ''
  GROUP BY ALL
),

combined AS (
  SELECT * FROM streaming_errors
  UNION ALL
  SELECT * FROM write_api_errors
),

totals AS (
  SELECT
    project_id,
    dataset_id,
    table_id,
    source_type,
    SUM(total_requests) AS all_requests
  FROM (
    SELECT
      project_id,
      dataset_id,
      table_id,
      'streaming' AS source_type,
      SUM(total_requests) AS total_requests
    FROM {{ ref('information_schema_streaming_timeline') }}
    WHERE start_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
    GROUP BY ALL
    UNION ALL
    SELECT
      project_id,
      dataset_id,
      table_id,
      'write_api' AS source_type,
      SUM(total_requests) AS total_requests
    FROM {{ ref('information_schema_write_api_timeline') }}
    WHERE start_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
    GROUP BY ALL
  )
  GROUP BY ALL
)

SELECT
  c.project_id,
  c.dataset_id,
  c.table_id,
  c.source_type,
  c.error_code,
  SUM(c.total_requests) AS error_request_count,
  SUM(c.total_rows) AS error_row_count,
  MIN(c.day) AS first_occurrence,
  MAX(c.day) AS last_occurrence,
  SAFE_DIVIDE(SUM(c.total_requests), ANY_VALUE(t.all_requests)) AS error_rate
FROM combined AS c
LEFT JOIN totals AS t USING (project_id, dataset_id, table_id, source_type)
GROUP BY c.project_id, c.dataset_id, c.table_id, c.source_type, c.error_code
ORDER BY error_request_count DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
