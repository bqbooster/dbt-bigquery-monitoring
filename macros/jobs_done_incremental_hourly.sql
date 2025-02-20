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

{% macro get_partition_logic() -%}
  {% if is_incremental() %}
    {{ get_partition_timestamp() }}
  {% else %}
    {{ lower_boundary_no_data() }}
  {% endif %}
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
            creation_time >= {{ get_partition_logic() }}
            {#- and if we enabled audit logs, we pushback to 6h before because of the potential delay of audit logs #}
            {% if enable_gcp_bigquery_audit_logs() %}
            AND hour >= TIMESTAMP_SUB(
                           TIMESTAMP_TRUNC({{ get_partition_logic() }}, HOUR),
                           INTERVAL 6 HOUR
                        )
            {% endif %}
            AND state = 'DONE'
    )
{%- endmacro %}
