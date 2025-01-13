{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "minute",
      "granularity": "hour",
      "data_type": "timestamp",
      "copy_partitions": should_use_copy_partitions()
    },
    cluster_by = ['minute', 'reservation_id', 'project_id'],
    partition_expiration_days = var('output_partition_expiration_days')
    )
}}
WITH
reservations_timeline AS (
SELECT
  TIMESTAMP_TRUNC(period_start, MINUTE) AS minute,
  reservation_id,
  project_id,
  ANY_VALUE(slots_assigned) AS slots_assigned,
  ANY_VALUE(slots_max_assigned) AS slots_max_assigned,
  ANY_VALUE(autoscale) AS autoscale
  FROM
  {{ ref("information_schema_reservations_timeline") }}
  WHERE
  {% if is_incremental() %}
  period_start >= TIMESTAMP_TRUNC(_dbt_max_partition, MINUTE)
  {% else %}
  period_start >= TIMESTAMP_SUB(
    TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), MINUTE),
    INTERVAL {{ var('lookback_window_days') }} DAY)
  {% endif %}
  GROUP BY ALL
)

SELECT
  minute,
  reservation_id,
  project_id,
  jobs.total_slot_ms,
  res.slots_assigned,
  res.slots_max_assigned,
  res.autoscale
FROM
  {{ ref('compute_cost_per_minute') }} AS jobs
INNER JOIN
  reservations_timeline AS res
  USING (minute, reservation_id, project_id)
