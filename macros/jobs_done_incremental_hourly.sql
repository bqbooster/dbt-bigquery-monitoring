{#- This intermediate model aims to return already done jobs that in the lookback window or starting the last partial partitions.
    The downstream jobs will use that model to aggregate all finished jobs as pending/running jobs metrics will evolve
    So the lookback is based on the max partition of the downstream model
#}

{#
  Returns the lower boundary timestamp when no data is available.
#}
{% macro lower_boundary_no_data() -%}
    TIMESTAMP_SUB(
        TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), HOUR),
        INTERVAL {{ var('lookback_window_days') }} DAY
    )
{%- endmacro %}

{#
  Returns the partition timestamp.
#}
{% macro get_partition_timestamp() -%}
    TIMESTAMP_TRUNC(
        CASE
            WHEN _dbt_max_partition IS NULL THEN {{ lower_boundary_no_data() }}
            ELSE _dbt_max_partition
        END,
        HOUR
    )
{%- endmacro %}

{#
  Returns done jobs within the specified time boundaries.
#}
{% macro jobs_done_incremental_hourly() -%}
    (
      SELECT *
      FROM {{ ref('jobs_with_cost') }}
      WHERE
          {#- the table already exists, we read logs are above latest max partition or above lookback window #}
          {% if is_incremental() %}
            creation_time >= {{ get_partition_timestamp() }}
            {#- and if we enabled audit logs, we pushback to 6h before because of the potential delay of audit logs #}
            {% if enable_gcp_bigquery_audit_logs() %}
              AND hour BETWEEN TIMESTAMP_SUB({{ get_partition_timestamp() }}, INTERVAL 6 HOUR)
                         AND {{ get_partition_timestamp() }}
            {% endif %}
          {#- if the table doesn't exist, we start from the lookback window #}
          {% else %}
            creation_time >= {{ lower_boundary_no_data() }}
            {#- if we enabled audit logs, we pushback to 6h before because of the potential delay of audit logs #}
            {% if enable_gcp_bigquery_audit_logs() %}
              AND hour >= TIMESTAMP_SUB(
                           TIMESTAMP_TRUNC({{ lower_boundary_no_data() }}, HOUR),
                           INTERVAL 6 HOUR
                         )
            {% endif %}
          {% endif %}
          AND state = 'DONE'
    )
{%- endmacro %}
