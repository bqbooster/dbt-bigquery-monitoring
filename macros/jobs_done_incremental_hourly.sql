{#- This intermediate model aims to return already done jobs that in the lookback window or starting the last partial partitions.
    The downstream jobs will use that model to aggregate all finished jobs as pending/running jobs metrics will evolve
    So the lookback is based on the max partition of the downstream model
#}
{% macro jobs_done_incremental_hourly() -%}
(SELECT *
FROM
  {{ ref('jobs_with_cost') }}
WHERE
{% if is_incremental() %}
creation_time >= TIMESTAMP_TRUNC(_dbt_max_partition, HOUR)
  {%- if enable_gcp_bigquery_audit_logs() %}
AND hour BETWEEN TIMESTAMP_SUB(TIMESTAMP_TRUNC(_dbt_max_partition, HOUR), INTERVAL 6 HOUR) AND TIMESTAMP_TRUNC(_dbt_max_partition, HOUR)
  {% endif %}
{% else %}
creation_time >= TIMESTAMP_SUB(
  TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), HOUR),
  INTERVAL {{ var('lookback_window_days') }} DAY)
  {%- if enable_gcp_bigquery_audit_logs() %}
AND hour >= TIMESTAMP_SUB(TIMESTAMP_TRUNC(TIMESTAMP_SUB(
TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), HOUR),
INTERVAL {{ var('lookback_window_days') }} DAY), HOUR), INTERVAL 6 HOUR)
  {% endif %}
{% endif %}
AND state = 'DONE'
)
{%- endmacro %}
