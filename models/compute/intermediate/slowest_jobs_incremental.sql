{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    partition_by = {
      "field": "hour",
      "data_type": "timestamp",
      "granularity": "hour"
    },
    cluster_by = ["hour", "user_email"],
    partition_expiration_days = var('lookback_window_days')
    )
}}
SELECT
  hour,
  job_id,
  query,
  query_cost,
  user_email,
  total_slot_ms,
  total_time_seconds,
  RANK() OVER (PARTITION BY hour ORDER BY total_time_seconds DESC) AS rank
FROM {{ ref('jobs_incremental') }}
QUALIFY rank <= {{ var('output_limit_size') }}
