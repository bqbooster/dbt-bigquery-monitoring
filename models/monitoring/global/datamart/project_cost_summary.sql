{{
   config(
    materialized='view',
    )
}}
{# Combined compute + storage cost summary per GCP project for executive dashboards #}
WITH compute AS (
  SELECT
    project_id,
    ROUND(SUM(total_query_cost), 2) AS compute_cost,
    SUM(query_count) AS query_count,
    SUM(unique_users) AS unique_users
  FROM {{ ref('compute_cost_per_hour') }}
  GROUP BY project_id
),

storage AS (
  SELECT
    project_id,
    ROUND(SUM(cost_monthly_forecast), 2) AS storage_monthly_forecast,
    ROUND(SUM(potential_savings), 2) AS storage_potential_savings,
    SUM(total_logical_bytes) AS total_logical_bytes,
    SUM(total_physical_bytes) AS total_physical_bytes,
    COUNT(*) AS table_count
  FROM {{ ref('storage_with_cost') }}
  GROUP BY project_id
)

SELECT
  COALESCE(c.project_id, s.project_id) AS project_id,
  COALESCE(c.compute_cost, 0) AS compute_cost,
  COALESCE(s.storage_monthly_forecast, 0) AS storage_monthly_forecast,
  COALESCE(c.compute_cost, 0) + COALESCE(s.storage_monthly_forecast, 0) AS total_estimated_cost,
  COALESCE(s.storage_potential_savings, 0) AS storage_potential_savings,
  COALESCE(c.query_count, 0) AS query_count,
  COALESCE(c.unique_users, 0) AS unique_users,
  s.total_logical_bytes,
  s.total_physical_bytes,
  COALESCE(s.table_count, 0) AS table_count
FROM compute AS c
FULL OUTER JOIN storage AS s USING (project_id)
ORDER BY total_estimated_cost DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
