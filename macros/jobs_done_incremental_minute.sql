{#- This intermediate model aims to return already done jobs that in the lookback window or starting the last partial partitions.
    The downstream jobs will use that model to aggregate all finished jobs as pending/running jobs metrics will evolve
    So the lookback is based on the max partition of the downstream model
#}
{% macro jobs_done_incremental_minute() -%}
(SELECT *
FROM
  {{ ref('jobs_by_project_with_cost') }}
WHERE
{% if is_incremental() %}
creation_time >= TIMESTAMP_TRUNC(_dbt_max_partition, MINUTE)
{% else %}
creation_time >= TIMESTAMP_SUB(
  TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), MINUTE),
  INTERVAL {{ var('lookback_window_days') }} DAY)
{% endif %}
AND state = 'DONE'
)
{%- endmacro %}
