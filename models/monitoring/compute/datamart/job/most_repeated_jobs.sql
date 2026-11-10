{{
   config(
    materialized='view',
    )
}}
{#-
  Default grouping is the raw query text, matching historical output.
  group_repeated_jobs_by_normalized_hash sums the hourly parent row once.
  Unnesting jobs to compute those totals multiplies each hour by the number
  of jobs in the bucket; that stays the default so existing numbers do not move.
-#}
{% if dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_group_repeated_jobs_by_normalized_hash() %}
WITH per_fingerprint AS (
  SELECT
    query_fingerprint,
    ANY_VALUE(normalized_query_hash) AS normalized_query_hash,
    APPROX_TOP_COUNT(query, 1)[SAFE_OFFSET(0)].value AS query,
    SUM(cache_hit) AS cache_hit,
    SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
    SUM(total_slot_ms) AS total_slot_ms,
    SUM(query_count) AS query_count
  FROM {{ ref('jobs_costs_incremental') }}
  GROUP BY query_fingerprint
),

top_dimensions AS (
  SELECT
    t.query_fingerprint,
    APPROX_TOP_SUM(j.project_id, 1, 100) AS project_ids,
    APPROX_TOP_SUM(j.reservation_id, 1, 100) AS reservation_ids,
    APPROX_TOP_SUM(j.user_email, 1, 100) AS user_emails
  FROM {{ ref('jobs_costs_incremental') }} AS t
  INNER JOIN UNNEST(t.jobs) AS j
  GROUP BY t.query_fingerprint
)

SELECT
  per_fingerprint.query,
  top_dimensions.project_ids,
  top_dimensions.reservation_ids,
  top_dimensions.user_emails,
  per_fingerprint.cache_hit / per_fingerprint.query_count AS cache_hit_ratio,
  per_fingerprint.total_query_cost,
  per_fingerprint.total_slot_ms,
  per_fingerprint.query_count,
  per_fingerprint.cache_hit,
  per_fingerprint.query_fingerprint,
  per_fingerprint.normalized_query_hash
FROM per_fingerprint
INNER JOIN top_dimensions USING (query_fingerprint)
WHERE per_fingerprint.query_count > 1
ORDER BY per_fingerprint.query_count DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
{% else %}
SELECT
  query,
  APPROX_TOP_SUM(j.project_id, 1, 100) AS project_ids,
  APPROX_TOP_SUM(j.reservation_id, 1, 100) AS reservation_ids,
  APPROX_TOP_SUM(j.user_email, 1, 100) AS user_emails,
  SUM(t.cache_hit) / SUM(t.query_count) AS cache_hit_ratio,
  SUM(ROUND(total_query_cost, 2)) AS total_query_cost,
  SUM(t.total_slot_ms) AS total_slot_ms,
  SUM(t.query_count) AS query_count,
  SUM(t.cache_hit) AS cache_hit,
  ANY_VALUE(t.query_fingerprint) AS query_fingerprint,
  ANY_VALUE(t.normalized_query_hash) AS normalized_query_hash,
FROM {{ ref('jobs_costs_incremental') }} AS t, UNNEST(jobs) AS j
GROUP BY query
HAVING query_count > 1
ORDER BY query_count DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
{% endif %}
