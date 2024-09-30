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
{%- call set_sql_header(config) %}
  {{ milliseconds_to_readable_time_udf() }}
{%- endcall %}
SELECT
  day,
  'compute' AS cost_category,
  SUM(total_query_cost) AS cost
FROM {{ ref('compute_cost_per_hour') }}
{% if is_incremental() %}
  WHERE hour >= TIMESTAMP_SUB(_dbt_max_partition, INTERVAL 1 DAY)
{% endif %}
GROUP BY day
{# TODO - add a union with storage_cost_per_hour once added #}
