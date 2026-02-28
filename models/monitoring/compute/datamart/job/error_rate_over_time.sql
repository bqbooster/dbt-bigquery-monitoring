{{
   config(
    materialized='view',
    )
}}
{# Time-series error rate by project and user — enables reliability monitoring and alert thresholds #}
WITH daily AS (
  SELECT
    TIMESTAMP_TRUNC(`hour`, DAY) AS day,
    project_id,
    j.user_email,
    COUNT(*) AS total_jobs,
    COUNTIF(j.error_result IS NOT NULL) AS failed_jobs,
    SUM(j.query_cost) AS failed_cost
  FROM {{ ref('jobs_costs_incremental') }},
  UNNEST(jobs) AS j
  GROUP BY day, project_id, j.user_email
)

SELECT
  day,
  project_id,
  user_email,
  total_jobs,
  failed_jobs,
  ROUND(SAFE_DIVIDE(failed_jobs, total_jobs) * 100, 2) AS error_rate_pct,
  ROUND(failed_cost, 4) AS wasted_cost_on_failures,
  -- Rolling 7-day average error rate per project
  ROUND(
    AVG(SAFE_DIVIDE(failed_jobs, total_jobs)) OVER (
      PARTITION BY project_id, user_email
      ORDER BY UNIX_SECONDS(CAST(day AS TIMESTAMP)) ASC
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) * 100,
    2
  ) AS rolling_7d_avg_error_rate_pct
FROM daily
ORDER BY day DESC, failed_jobs DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
