{{
   config(
    materialized='view',
    )
}}

WITH failed_jobs AS (
  SELECT
    hour,
    query,
    j.*,
    j.error_result.reason AS error_reason,
    j.error_result.message AS error_message,
    j.error_result.location AS error_location
  FROM {{ ref('jobs_costs_incremental') }}, UNNEST(jobs) AS j
  WHERE j.error_result IS NOT NULL
),

error_patterns AS (
  SELECT
    error_reason,
    error_message,
    COUNT(*) AS error_count,
    APPROX_TOP_SUM(project_id, 1, 10) AS affected_projects,
    APPROX_TOP_SUM(user_email, 1, 10) AS affected_users,
    SUM(query_cost) AS total_failed_cost,
    AVG(total_slot_ms) AS avg_slot_ms,
    MIN(hour) AS first_occurrence,
    MAX(hour) AS last_occurrence
  FROM failed_jobs
  GROUP BY error_reason, error_message
)

SELECT
  error_reason,
  error_message,
  error_count,
  {{ top_sum('affected_projects') }} AS top_affected_projects,
  {{ top_sum('affected_users') }} AS top_affected_users,
  ROUND(total_failed_cost, 2) AS total_failed_cost,
  ROUND(avg_slot_ms / 1000, 2) AS avg_slot_seconds,
  first_occurrence,
  last_occurrence,
  DATETIME_DIFF(last_occurrence, first_occurrence, HOUR) AS duration_hours
FROM error_patterns
ORDER BY error_count DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
