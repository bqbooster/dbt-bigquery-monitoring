{{
   config(
    materialized='view',
    )
}}
{#
  Identifies queries that are strong candidates for caching or materialization:
  - run frequently (high query_count)
  - have significant cost (high total_query_cost)
  - have low or no cache hit rate (cache_hit_ratio is low)
  These queries would benefit from scheduled queries, materialized views, or BI Engine acceleration.
#}
WITH aggregated AS (
  SELECT
    query,
    SUM(cache_hit) AS cache_hits,
    SUM(query_count) AS query_count,
    ROUND(SUM(total_query_cost), 4) AS total_query_cost,
    ROUND(SUM(total_query_cost) / NULLIF(SUM(query_count), 0), 4) AS avg_query_cost,
    SUM(total_slot_ms) AS total_slot_ms,
    AVG(avg_duration_seconds) AS avg_duration_seconds,
    SUM(total_bytes_processed) AS total_bytes_processed,
    SUM(total_bytes_billed) AS total_bytes_billed,
    MIN(hour) AS first_seen,
    MAX(hour) AS last_seen
  FROM {{ ref('jobs_costs_incremental') }}
  GROUP BY query
),

distinct_projects AS (
  SELECT
    query,
    COUNT(DISTINCT job.project_id) AS distinct_project_count
  FROM {{ ref('jobs_costs_incremental') }},
    UNNEST(jobs) AS job
  GROUP BY query
),

candidates AS (
  SELECT
    a.*,
    dp.distinct_project_count,
    SAFE_DIVIDE(a.cache_hits, a.query_count) AS cache_hit_ratio,
    -- Potential savings: cost that would be avoided if all repeated executions hit cache
    ROUND(a.total_query_cost * (1 - SAFE_DIVIDE(a.cache_hits, a.query_count)), 4) AS potential_savings_from_caching,
    CASE
      WHEN a.query_count >= 10 AND a.total_query_cost >= 1 AND SAFE_DIVIDE(a.cache_hits, a.query_count) < 0.1
        THEN 'High — consider materialized view or scheduled query'
      WHEN a.query_count >= 5 AND a.total_query_cost >= 0.1 AND SAFE_DIVIDE(a.cache_hits, a.query_count) < 0.2
        THEN 'Medium — caching could help'
      ELSE 'Low'
    END AS materialization_recommendation
  FROM aggregated AS a
  LEFT JOIN distinct_projects AS dp USING (query)
)

SELECT
  query,
  query_count,
  total_query_cost,
  avg_query_cost,
  cache_hits,
  ROUND(cache_hit_ratio, 4) AS cache_hit_ratio,
  potential_savings_from_caching,
  total_slot_ms,
  ROUND(avg_duration_seconds, 2) AS avg_duration_seconds,
  ROUND(total_bytes_processed / POW(1024, 3), 2) AS total_gb_processed,
  first_seen,
  last_seen,
  materialization_recommendation
FROM candidates
WHERE materialization_recommendation != 'Low'
ORDER BY potential_savings_from_caching DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
