{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "hour",
      "granularity": "day",
      "data_type": "timestamp",
      "copy_partitions": dbt_bigquery_monitoring_variable_use_copy_partitions()
    },
    cluster_by = ['hour', 'reservation_id', 'project_id'],
    partition_expiration_days = dbt_bigquery_monitoring_variable_output_partition_expiration_days()
    )
}}

SELECT
  TIMESTAMP_TRUNC(MINUTE, HOUR) AS hour,
  reservation_id,
  project_id,
  SUM(total_slot_ms) AS total_slot_ms,
  ANY_VALUE(slots_assigned) AS slots_assigned,
  ANY_VALUE(slots_max_assigned) AS slots_max_assigned,
  ANY_VALUE(autoscale) AS autoscale,
  -- Enhanced metrics
  SUM(total_query_cost) AS total_query_cost,
  SUM(query_count) AS query_count,
  -- Reservation efficiency calculations
  SAFE_DIVIDE(SUM(total_slot_ms), ANY_VALUE(slots_assigned) * 3600 * 1000) AS slot_utilization_ratio,
  SAFE_DIVIDE(SUM(total_slot_ms), ANY_VALUE(slots_max_assigned) * 3600 * 1000) AS max_slot_utilization_ratio,
  -- Usage patterns
  CASE
    WHEN SAFE_DIVIDE(SUM(total_slot_ms), ANY_VALUE(slots_assigned) * 3600 * 1000) > 0.9 THEN 'High Utilization'
    WHEN SAFE_DIVIDE(SUM(total_slot_ms), ANY_VALUE(slots_assigned) * 3600 * 1000) > 0.6 THEN 'Medium Utilization'
    WHEN SAFE_DIVIDE(SUM(total_slot_ms), ANY_VALUE(slots_assigned) * 3600 * 1000) > 0.3 THEN 'Low Utilization'
    ELSE 'Very Low Utilization'
  END AS utilization_category,
  -- Autoscaling effectiveness
  CASE
    WHEN ANY_VALUE(autoscale) IS NOT NULL AND ANY_VALUE(slots_max_assigned) > ANY_VALUE(slots_assigned) THEN 'Autoscaling Active'
    WHEN ANY_VALUE(autoscale) IS NOT NULL AND ANY_VALUE(slots_max_assigned) = ANY_VALUE(slots_assigned) THEN 'Autoscaling Available'
    ELSE 'Fixed Capacity'
  END AS autoscaling_status
FROM
  {{ ref('reservation_usage_per_minute') }}
GROUP BY ALL
