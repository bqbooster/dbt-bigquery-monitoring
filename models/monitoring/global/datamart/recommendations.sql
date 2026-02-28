{{
   config(
    materialized='view',
    )
}}
{# Surfaces active BigQuery recommendations from Google (partitioning, clustering, materialized views, etc.) #}
WITH recommendations AS (
  SELECT
    recommendation_id,
    recommender,
    subtype,
    project_id,
    description,
    last_updated_time,
    state,
    priority,
    target_resources,
    primary_impact,
    additional_details
  FROM {{ ref('information_schema_recommendations') }}
  WHERE state = 'ACTIVE'
),

enriched AS (
  SELECT
    recommendation_id,
    project_id,
    recommender,
    subtype,
    description,
    last_updated_time,
    priority,
    state,
    target_resources,
    -- Extract cost impact when available
    JSON_VALUE(TO_JSON_STRING(primary_impact), '$.category') AS impact_category,
    JSON_VALUE(TO_JSON_STRING(primary_impact), '$.costProjection.cost.units') AS estimated_monthly_savings_units,
    JSON_VALUE(TO_JSON_STRING(primary_impact), '$.costProjection.cost.nanos') AS estimated_monthly_savings_nanos,
    CASE recommender
      WHEN 'google.bigquery.table.PartitionClusterRecommender' THEN 'Partition / Cluster Table'
      WHEN 'google.bigquery.table.MaterializedViewRecommender' THEN 'Create Materialized View'
      WHEN 'google.bigquery.capacityCommitments.Recommender' THEN 'Capacity Commitment'
      WHEN 'google.bigquery.table.IdleTableRecommender' THEN 'Remove Idle Table'
      ELSE recommender
    END AS recommender_label,
    CASE priority
      WHEN 'P1' THEN 1
      WHEN 'P2' THEN 2
      WHEN 'P3' THEN 3
      WHEN 'P4' THEN 4
      ELSE 5
    END AS priority_rank
  FROM recommendations
)

SELECT
  project_id,
  recommender_label,
  subtype,
  description,
  priority,
  priority_rank,
  impact_category,
  -- Convert cost savings to a numeric value (units + nanos/1e9)
  SAFE_CAST(estimated_monthly_savings_units AS FLOAT64)
    + SAFE_CAST(estimated_monthly_savings_nanos AS FLOAT64) / 1000000000
    AS estimated_monthly_savings,
  target_resources,
  last_updated_time,
  recommendation_id
FROM enriched
ORDER BY priority_rank ASC, estimated_monthly_savings DESC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
