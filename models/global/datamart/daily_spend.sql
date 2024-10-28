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
with compute_cost as (
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
  select
    day,
    'compute' as cost_category,
    SUM(total_query_cost) as cost
  from {{ ref('compute_cost_per_hour_view') }}
  {% if is_incremental() %}
    where hour >= TIMESTAMP_SUB(_dbt_max_partition, interval 1 day)
  {% endif %}
  group by all
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
select
  day,
  cost_category,
  SUM(cost) as cost
from (
  select * from compute_cost
  {%- if enable_gcp_billing_export() %}
  UNION ALL
  SELECT * FROM storage_cost
  {%- endif %}
)
group by all
