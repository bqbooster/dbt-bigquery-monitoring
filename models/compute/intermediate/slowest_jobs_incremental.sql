{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    partition_by = {
      "field": "hour",
      "data_type": "timestamp",
      "granularity": "hour"
    },
    cluster_by = ["user_email"],
    partition_expiration_days = var('lookback_window_days')
    )
}}
SELECT
  hour,
  job_id,
  query,
  query_cost,
  user_email,
  total_slot_ms
FROM {{ ref('jobs_incremental') }}
ORDER BY total_time_seconds DESC
LIMIT {{ var('output_limit_size') }}
