{{
   config(
    materialized='view',
    )
}}

-- This model analyzes BI Engine usage and effectiveness
WITH bi_engine_jobs AS (
  SELECT
    project_id,
    user_email,
    job_id,
    query,
    creation_time,
    total_slot_ms,
    total_bytes_processed,
    cache_hit,
    -- BI Engine statistics
    bi_engine_statistics.bi_engine_mode,
    bi_engine_statistics.bi_engine_reasons
  FROM {{ ref('jobs_with_cost') }}
  WHERE bi_engine_statistics IS NOT NULL
),

bi_engine_performance AS (
  SELECT
    project_id,
    bi_engine_mode,
    COUNT(*) AS total_queries,
    COUNT(DISTINCT user_email) AS unique_users,
    AVG(total_slot_ms) AS avg_slot_ms,
    SUM(total_bytes_processed) AS total_bytes_processed,
    AVG(CASE WHEN cache_hit THEN 1.0 ELSE 0.0 END) AS cache_hit_rate,
    STRING_AGG(DISTINCT
      (SELECT STRING_AGG(reason.code, ', ')
       FROM UNNEST(bi_engine_reasons) AS reason),
    '; ') AS common_reasons
  FROM bi_engine_jobs
  WHERE bi_engine_mode IS NOT NULL
  GROUP BY project_id, bi_engine_mode
)

SELECT
  project_id,
  bi_engine_mode,
  total_queries AS bi_engine_queries,
  ROUND(avg_slot_ms / 1000, 2) AS bi_engine_avg_slot_seconds,
  ROUND(cache_hit_rate * 100, 1) AS bi_engine_cache_hit_percentage,
  -- Efficiency analysis
  CASE
    WHEN avg_slot_ms < 1000 THEN 'High Performance'
    WHEN avg_slot_ms < 5000 THEN 'Good Performance'
    ELSE 'Standard Performance'
  END AS bi_engine_performance_tier,
  common_reasons AS bi_engine_reasons,
  -- Recommendations
  CASE
    WHEN total_queries = 0 THEN 'Consider enabling BI Engine for faster queries'
    WHEN avg_slot_ms > 5000 THEN 'Optimize queries to better leverage BI Engine'
    ELSE 'Well optimized BI Engine usage'
  END AS optimization_recommendation
FROM bi_engine_performance
ORDER BY total_queries DESC
LIMIT {{ var('output_limit_size') }}
