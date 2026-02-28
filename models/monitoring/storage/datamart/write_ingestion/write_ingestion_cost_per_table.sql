{{
   config(
    materialized='view',
    )
}}
{#
  Combines Streaming API and Storage Write API ingestion volume and estimated cost per table per day.
  source_type = 'streaming' | 'write_api'
  Pricing reference:
    Streaming inserts: $0.01 per 200 MB = $0.00005 per MB
    Storage Write API: $0.025 per GB committed stream (approximated from default stream usage)
#}
WITH streaming AS (
  SELECT
    TIMESTAMP_TRUNC(start_timestamp, DAY) AS day,
    project_id,
    dataset_id,
    table_id,
    'streaming' AS source_type,
    SUM(total_requests) AS total_requests,
    SUM(total_rows) AS total_rows,
    SUM(total_input_bytes) AS total_input_bytes,
    COUNTIF(error_code IS NOT NULL AND error_code != '') AS error_count,
    SUM(total_input_bytes) / POW(1024, 2) * 0.00005 AS estimated_cost
  FROM {{ ref('information_schema_streaming_timeline') }}
  WHERE start_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
  GROUP BY ALL
),

write_api AS (
  SELECT
    TIMESTAMP_TRUNC(start_timestamp, DAY) AS day,
    project_id,
    dataset_id,
    table_id,
    'write_api' AS source_type,
    SUM(total_requests) AS total_requests,
    SUM(total_rows) AS total_rows,
    SUM(total_input_bytes) AS total_input_bytes,
    COUNTIF(error_code IS NOT NULL AND error_code != '') AS error_count,
    -- Storage Write API: ~$0.025/GB for committed streams (default stream is free but approximated here)
    SUM(total_input_bytes) / POW(1024, 3) * 0.025 AS estimated_cost
  FROM {{ ref('information_schema_write_api_timeline') }}
  WHERE start_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
  GROUP BY ALL
)

SELECT
  day,
  project_id,
  dataset_id,
  table_id,
  source_type,
  total_requests,
  total_rows,
  total_input_bytes,
  ROUND(total_input_bytes / POW(1024, 2), 2) AS total_input_mb,
  error_count,
  SAFE_DIVIDE(error_count, total_requests) AS error_rate,
  ROUND(estimated_cost, 6) AS estimated_cost
FROM (
  SELECT * FROM streaming
  UNION ALL
  SELECT * FROM write_api
)
ORDER BY estimated_cost DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
