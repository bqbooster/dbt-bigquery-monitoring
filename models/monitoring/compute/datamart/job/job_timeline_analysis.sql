{{
   config(
    materialized='view',
    )
}}

-- This model leverages JOBS_TIMELINE to provide detailed slot utilization analysis
WITH timeline_base AS (
  SELECT
    project_id,
    user_email,
    job_id,
    job_type,
    statement_type,
    reservation_id,
    period_start,
    period_slot_ms,
    job_creation_time,
    job_start_time,
    job_end_time,
    state,
    cache_hit,
    total_bytes_processed,
    total_bytes_billed,
    TIMESTAMP_DIFF(job_end_time, job_start_time, SECOND) AS job_duration_seconds,
    TIMESTAMP_DIFF(job_start_time, job_creation_time, SECOND) AS queue_time_seconds
  FROM {{ ref('information_schema_jobs_timeline') }}
  WHERE job_creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ var('lookback_window_days') }} DAY)
    AND period_start >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ var('lookback_window_days') }} DAY)
),

slot_utilization AS (
  SELECT
    project_id,
    user_email,
    job_id,
    job_type,
    statement_type,
    COALESCE(reservation_id, 'on-demand') AS pricing_model,
    job_creation_time,
    job_duration_seconds,
    queue_time_seconds,
    cache_hit,
    total_bytes_processed,
    total_bytes_billed,
    SUM(period_slot_ms) AS total_slot_ms,
    COUNT(*) AS timeline_periods,
    -- Peak slot usage analysis
    MAX(period_slot_ms) AS peak_period_slot_ms,
    AVG(period_slot_ms) AS avg_period_slot_ms,
    STDDEV(period_slot_ms) AS slot_usage_variance,
    -- Efficiency metrics
    SUM(period_slot_ms) / NULLIF(job_duration_seconds * 1000, 0) AS slot_utilization_ratio
  FROM timeline_base
  WHERE state = 'DONE'
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
),

job_performance_analysis AS (
  SELECT
    *,
    -- Performance classifications
    CASE
      WHEN queue_time_seconds > 300 THEN 'High Queue Time'
      WHEN queue_time_seconds > 60 THEN 'Medium Queue Time'
      ELSE 'Low Queue Time'
    END AS queue_performance,

    CASE
      WHEN slot_utilization_ratio > 0.8 THEN 'High Utilization'
      WHEN slot_utilization_ratio > 0.4 THEN 'Medium Utilization'
      ELSE 'Low Utilization'
    END AS slot_efficiency,

    CASE
      WHEN job_duration_seconds > 3600 THEN 'Long Running'
      WHEN job_duration_seconds > 300 THEN 'Medium Duration'
      ELSE 'Quick Job'
    END AS duration_category,

    -- Cost efficiency indicators
    total_bytes_processed / NULLIF(total_slot_ms, 0) AS bytes_per_slot_ms,
    total_slot_ms / NULLIF(job_duration_seconds * 1000, 0) AS slot_parallelism_factor
  FROM slot_utilization
),

aggregated_insights AS (
  SELECT
    project_id,
    user_email,
    job_type,
    statement_type,
    pricing_model,
    queue_performance,
    slot_efficiency,
    duration_category,
    COUNT(*) AS job_count,
    AVG(job_duration_seconds) AS avg_duration_seconds,
    AVG(queue_time_seconds) AS avg_queue_seconds,
    AVG(total_slot_ms) AS avg_slot_ms,
    SUM(total_slot_ms) AS total_slot_ms,
    AVG(slot_utilization_ratio) AS avg_slot_utilization,
    AVG(bytes_per_slot_ms) AS avg_bytes_per_slot_ms,
    SUM(total_bytes_processed) AS total_bytes_processed,
    AVG(CASE WHEN cache_hit THEN 1.0 ELSE 0.0 END) AS cache_hit_rate
  FROM job_performance_analysis
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT
  project_id,
  user_email,
  job_type,
  statement_type,
  pricing_model,
  queue_performance,
  slot_efficiency,
  duration_category,
  job_count,
  ROUND(avg_duration_seconds, 2) AS avg_duration_seconds,
  ROUND(avg_queue_seconds, 2) AS avg_queue_seconds,
  ROUND(avg_slot_ms / 1000, 2) AS avg_slot_seconds,
  ROUND(total_slot_ms / 1000, 2) AS total_slot_seconds,
  ROUND(avg_slot_utilization * 100, 1) AS avg_slot_utilization_pct,
  ROUND(avg_bytes_per_slot_ms, 2) AS avg_bytes_per_slot_ms,
  ROUND(total_bytes_processed / POWER(1024, 3), 2) AS total_gb_processed,
  ROUND(cache_hit_rate * 100, 1) AS cache_hit_rate_pct,
  -- Performance recommendations
  CASE
    WHEN queue_performance = 'High Queue Time' AND slot_efficiency = 'Low Utilization'
      THEN 'Consider optimizing queries or using reservations'
    WHEN slot_efficiency = 'Low Utilization' AND duration_category = 'Long Running'
      THEN 'Query optimization needed - poor slot utilization'
    WHEN cache_hit_rate < 0.1 AND job_count > 5
      THEN 'Enable query caching for repeated queries'
    WHEN avg_slot_utilization > 0.9
      THEN 'Efficient slot usage - well optimized'
    ELSE 'Review query patterns for optimization opportunities'
  END AS optimization_recommendation
FROM aggregated_insights
ORDER BY total_slot_ms DESC
LIMIT {{ var('output_limit_size') }}
