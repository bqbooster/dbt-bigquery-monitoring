{{
   config(
    materialized='ephemeral',
    )
}}
SELECT
  *
FROM
  {{ ref('jobs_by_project_with_cost') }}
{% if is_incremental_run() %}
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{ var('lookback_window_days') }} DAY)
{% else %}
WHERE creation_time > {{ run_schedule_lower_bound() }}
{% endif %}
