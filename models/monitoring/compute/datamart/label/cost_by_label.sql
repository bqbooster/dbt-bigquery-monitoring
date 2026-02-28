{{
   config(
    materialized='view',
    )
}}
{# Breaks down compute cost by BigQuery job label key+value for FinOps chargeback and cost allocation #}
WITH jobs_with_labels AS (
  SELECT
    TIMESTAMP_TRUNC(creation_time, DAY) AS day,
    project_id,
    user_email,
    query_cost,
    total_slot_ms,
    total_bytes_processed,
    cache_hit,
    error_result,
    label.key AS label_key,
    label.value AS label_value
  FROM {{ ref('jobs_with_cost') }},
  UNNEST(labels) AS label
  WHERE state = 'DONE'
    AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
)

SELECT
  day,
  label_key,
  label_value,
  project_id,
  COUNT(DISTINCT user_email) AS unique_users,
  COUNT(*) AS query_count,
  COUNTIF(cache_hit) AS cache_hits,
  COUNTIF(error_result IS NOT NULL) AS failed_queries,
  ROUND(SUM(query_cost), 4) AS total_query_cost,
  ROUND(AVG(query_cost), 4) AS avg_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SAFE_DIVIDE(COUNTIF(cache_hit), COUNT(*)) AS cache_hit_ratio
FROM jobs_with_labels
GROUP BY day, label_key, label_value, project_id
ORDER BY total_query_cost DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
