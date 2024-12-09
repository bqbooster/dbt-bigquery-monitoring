{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "day",
      "data_type": "timestamp",
      "copy_partitions": should_use_copy_partitions()
    },
    )
}}
WITH compute_cost AS (
  {#- we use the billing export if possible else fallback to the estimated comput cost #}
  {%- if enable_gcp_billing_export() %}
  SELECT day,
    'compute' AS cost_category,
    SUM(compute_cost) AS cost
  FROM {{ ref('compute_billing_per_hour') }}
  {% if is_incremental() %}
    WHERE hour >= TIMESTAMP_SUB(_dbt_max_partition, INTERVAL 1 DAY)
  {% endif %}
  GROUP BY ALL
  {%- else %}
  SELECT
    day,
    'compute' AS cost_category,
    SUM(total_query_cost) AS cost
  FROM {{ ref('compute_cost_per_hour_view') }}
  {% if is_incremental() %}
    WHERE hour >= TIMESTAMP_SUB(_dbt_max_partition, INTERVAL 1 DAY)
  {% endif %}
  GROUP BY ALL
  {% endif %}
)
{%- if enable_gcp_billing_export() %}
,
storage_cost AS (
  SELECT
    day,
    'storage' AS cost_category,
    SUM(storage_cost) AS cost
  FROM {{ ref('storage_billing_per_hour') }}
  {% if is_incremental() %}
    WHERE hour >= TIMESTAMP_SUB(_dbt_max_partition, INTERVAL 1 DAY)
  {% endif %}
  GROUP BY day
)
{%- endif %}
SELECT
  day,
  cost_category,
  SUM(cost) AS cost
FROM (
  SELECT * FROM compute_cost
  {%- if enable_gcp_billing_export() %}
  UNION ALL
  SELECT * FROM storage_cost
  {%- endif %}
)
GROUP BY ALL
