{{
   config(
    materialized='view',
    )
}}
{# Daily compute cost breakdown per GCP project, enabling cross-project comparison and cost ranking #}
SELECT
  TIMESTAMP_TRUNC(`hour`, DAY) AS day,
  project_id,
  ROUND(SUM(total_query_cost), 2) AS total_query_cost,
  ROUND(SUM(failing_query_cost), 2) AS total_failing_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  SUM(query_count) AS query_count,
  SUM(unique_users) AS unique_users,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SUM(total_bytes_billed) AS total_bytes_billed,
  SUM(cache_hits) AS cache_hits,
  SAFE_DIVIDE(SUM(cache_hits), SUM(query_count)) AS cache_hit_ratio,
  ROUND(AVG(avg_duration_seconds), 2) AS avg_duration_seconds
FROM {{ ref('compute_cost_per_hour') }}
GROUP BY day, project_id
ORDER BY total_query_cost DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
