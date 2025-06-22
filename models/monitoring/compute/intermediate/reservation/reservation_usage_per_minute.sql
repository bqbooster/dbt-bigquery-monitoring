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
  res.autoscale,
  -- Enhanced metrics
  jobs.total_query_cost,
  jobs.query_count,
  -- Reservation efficiency calculations
  SAFE_DIVIDE(jobs.total_slot_ms, res.slots_assigned * 60 * 1000) AS slot_utilization_ratio,
  SAFE_DIVIDE(jobs.total_slot_ms, res.slots_max_assigned * 60 * 1000) AS max_slot_utilization_ratio,
  -- Usage patterns
  CASE
    WHEN SAFE_DIVIDE(jobs.total_slot_ms, res.slots_assigned * 60 * 1000) > 0.9 THEN 'High Utilization'
    WHEN SAFE_DIVIDE(jobs.total_slot_ms, res.slots_assigned * 60 * 1000) > 0.6 THEN 'Medium Utilization'
    WHEN SAFE_DIVIDE(jobs.total_slot_ms, res.slots_assigned * 60 * 1000) > 0.3 THEN 'Low Utilization'
    ELSE 'Very Low Utilization'
  END AS utilization_category,
  -- Autoscaling effectiveness
  CASE
    WHEN res.autoscale IS NOT NULL AND res.slots_max_assigned > res.slots_assigned THEN 'Autoscaling Active'
    WHEN res.autoscale IS NOT NULL AND res.slots_max_assigned = res.slots_assigned THEN 'Autoscaling Available'
    ELSE 'Fixed Capacity'
  END AS autoscaling_status
FROM
  {{ ref('compute_cost_per_minute') }} AS jobs
INNER JOIN
  reservations_timeline AS res
  USING (minute, reservation_id, project_id)
