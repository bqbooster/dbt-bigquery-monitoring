{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    cluster_by = ["project_id", "dataset_id", "table_id"],
    partition_by = {
      "field": "day",
      "data_type": "timestamp"
    },
    )
}}
SELECT
  TIMESTAMP_TRUNC(creation_time, DAY) day,
  rt.project_id,
  rt.dataset_id,
  rt.table_id,
  count(*) AS reference_count
FROM {{ ref('jobs_by_project_with_cost') }}, unnest(referenced_tables) AS rt
{% if is_incremental_run() %}
WHERE creation_time > _dbt_max_partition
{% else %}
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ var('lookback_window_days') }} DAY)
{% endif %}
GROUP BY 1, 2, 3, 4
