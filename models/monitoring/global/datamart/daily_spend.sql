{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "day",
      "data_type": "timestamp",
      "copy_partitions": dbt_bigquery_monitoring_variable_use_copy_partitions()
    },
    )
}}
WITH compute_cost AS (
  {#- we use the billing export if possible else fallback to the estimated comput cost #}
  {%- if dbt_bigquery_monitoring_variable_enable_gcp_billing_export() %}
  SELECT TIMESTAMP_TRUNC(hour, DAY) AS day,
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
{%- if dbt_bigquery_monitoring_variable_enable_gcp_billing_export() %}
,
storage_cost AS (
  SELECT
    TIMESTAMP_TRUNC(HOUR, DAY) AS day,
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
  SELECT
day,
cost_category,
cost
FROM compute_cost
  {%- if dbt_bigquery_monitoring_variable_enable_gcp_billing_export() %}
  UNION ALL
  SELECT
    day,
    cost_category,
    cost
  FROM storage_cost AS s
  {%- endif %}
)
GROUP BY ALL
