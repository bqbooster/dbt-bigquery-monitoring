{{
   config(
    materialized='view',
    )
}}

-- This model analyzes BI Engine usage and materialized view effectiveness
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
    bi_engine_statistics.bi_engine_reasons,
    -- Materialized view statistics
    materialized_view_statistics.materialized_view
  FROM {{ ref('jobs_with_cost') }}
  WHERE bi_engine_statistics IS NOT NULL
     OR materialized_view_statistics IS NOT NULL
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
    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT bi_engine_reasons IGNORE NULLS), ', ') AS common_reasons
  FROM bi_engine_jobs
  WHERE bi_engine_mode IS NOT NULL
  GROUP BY project_id, bi_engine_mode
),

materialized_view_usage AS (
  SELECT
    project_id,
    COUNT(*) AS queries_using_mv,
    COUNT(DISTINCT user_email) AS users_using_mv,
    AVG(total_slot_ms) AS avg_slot_ms_with_mv,
    STRING_AGG(DISTINCT CONCAT(
      materialized_view.table_reference.dataset_id, '.',
      materialized_view.table_reference.table_id
    )) AS mv_tables_used
  FROM bi_engine_jobs, UNNEST(materialized_view_statistics.materialized_view) AS materialized_view
  WHERE materialized_view IS NOT NULL
  GROUP BY project_id
),

performance_comparison AS (
  SELECT
    p.project_id,
    -- BI Engine metrics
    be.bi_engine_mode,
    be.total_queries AS bi_engine_queries,
    be.avg_slot_ms AS bi_engine_avg_slot_ms,
    be.cache_hit_rate AS bi_engine_cache_hit_rate,
    be.common_reasons AS bi_engine_reasons,
    -- Materialized view metrics
    mv.queries_using_mv,
    mv.avg_slot_ms_with_mv,
    mv.mv_tables_used,
    -- Efficiency analysis
    CASE
      WHEN be.avg_slot_ms < 1000 THEN 'High Performance'
      WHEN be.avg_slot_ms < 5000 THEN 'Good Performance'
      ELSE 'Standard Performance'
    END AS bi_engine_performance_tier
  FROM (SELECT DISTINCT project_id FROM bi_engine_jobs) p
  LEFT JOIN bi_engine_performance be ON p.project_id = be.project_id
  LEFT JOIN materialized_view_usage mv ON p.project_id = mv.project_id
)

SELECT
  project_id,
  bi_engine_mode,
  COALESCE(bi_engine_queries, 0) AS bi_engine_queries,
  ROUND(bi_engine_avg_slot_ms / 1000, 2) AS bi_engine_avg_slot_seconds,
  ROUND(bi_engine_cache_hit_rate * 100, 1) AS bi_engine_cache_hit_percentage,
  bi_engine_performance_tier,
  bi_engine_reasons,
  COALESCE(queries_using_mv, 0) AS queries_using_materialized_views,
  ROUND(avg_slot_ms_with_mv / 1000, 2) AS avg_slot_seconds_with_mv,
  mv_tables_used,
  -- Recommendations
  CASE
    WHEN bi_engine_queries = 0 THEN 'Consider enabling BI Engine for faster queries'
    WHEN queries_using_mv = 0 THEN 'Consider creating materialized views for repeated queries'
    WHEN bi_engine_performance_tier = 'Standard Performance'
      THEN 'Optimize queries to better leverage BI Engine'
    ELSE 'Well optimized BI Engine and materialized view usage'
  END AS optimization_recommendation
FROM performance_comparison
WHERE (bi_engine_queries > 0 OR queries_using_mv > 0)
ORDER BY bi_engine_queries DESC, queries_using_mv DESC
LIMIT {{ var('output_limit_size') }}
