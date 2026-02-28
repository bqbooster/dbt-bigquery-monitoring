{{
   config(
    materialized='view',
    )
}}
{# Daily cost and performance trends per dbt model — enables detecting regressions and cost spikes over time #}
SELECT
  TIMESTAMP_TRUNC(`hour`, DAY) AS day,
  dbt_model_name,
  SUM(query_count) AS query_count,
  ROUND(SUM(total_query_cost), 4) AS total_query_cost,
  ROUND(AVG(total_query_cost / NULLIF(query_count, 0)), 4) AS avg_query_cost,
  SUM(total_slot_ms) AS total_slot_ms,
  ROUND(AVG(avg_duration_seconds), 2) AS avg_duration_seconds,
  MAX(max_duration_seconds) AS max_duration_seconds,
  ROUND(AVG(median_duration_seconds), 2) AS median_duration_seconds,
  ROUND(AVG(p90_duration_seconds), 2) AS p90_duration_seconds,
  SUM(failed_runs) AS failed_runs,
  SAFE_DIVIDE(SUM(failed_runs), SUM(query_count)) AS failure_rate,
  SUM(cache_hit) AS cache_hits,
  SAFE_DIVIDE(SUM(cache_hit), SUM(query_count)) AS cache_hit_ratio,
  SUM(total_bytes_processed) AS total_bytes_processed,
  SUM(total_bytes_billed) AS total_bytes_billed
FROM {{ ref('models_costs_incremental') }}
WHERE dbt_model_name IS NOT NULL
GROUP BY day, dbt_model_name
ORDER BY day DESC, total_query_cost DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
