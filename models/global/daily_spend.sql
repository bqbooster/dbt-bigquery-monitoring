{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "day",
      "data_type": "timestamp"
    },
    )
}}
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  day,
  'compute' as cost_category,
  SUM(total_query_cost) AS cost
FROM {{ ref('compute_cost_per_hour') }}
{% if is_incremental() %}
  where hour >= timestamp_sub(_dbt_max_partition, interval 1 day)
{% endif %}
GROUP BY day
