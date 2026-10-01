{#- This intermediate model aims to return already done jobs that in the lookback window or starting the last partial partitions.
    The downstream jobs will use that model to aggregate all finished jobs as pending/running jobs metrics will evolve
    So the lookback is based on the max partition of the downstream model
#}

{#
  Returns the lower boundary timestamp when no data is available.
  Default granularity is HOUR so existing jobs incrementals keep the same compiled SQL.
#}
{% macro lower_boundary_no_data(granularity='HOUR') -%}
    TIMESTAMP_SUB(
        TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), {{ granularity }}),
        INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY
    )
{%- endmacro %}

{#
  Use when an incremental predicate subtracts from `_dbt_max_partition`.
  An empty target leaves that symbol NULL; without a fallback the predicate matches nothing.
#}
{% macro coalesce_dbt_max_partition(null_fallback) -%}
COALESCE(_dbt_max_partition, {{ null_fallback }})
{%- endmacro %}

{#
  Returns the partition timestamp.
  Default granularity is HOUR so existing jobs incrementals keep the same compiled SQL.
#}
{% macro get_partition_timestamp(granularity='HOUR') -%}
    TIMESTAMP_TRUNC(
        CASE
            WHEN _dbt_max_partition IS NULL THEN {{ lower_boundary_no_data(granularity) }}
            ELSE _dbt_max_partition
        END,
        {{ granularity }}
    )
{%- endmacro %}

{% macro get_partition_logic(granularity='HOUR') -%}
  {% if is_incremental() %}
    {{ get_partition_timestamp(granularity) }}
  {% else %}
    {{ lower_boundary_no_data(granularity) }}
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
            {% if dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() %}
            AND hour >= TIMESTAMP_SUB(
                           TIMESTAMP_TRUNC({{ get_partition_logic() }}, HOUR),
                           INTERVAL 6 HOUR
                        )
            {% endif %}
            AND state = 'DONE'
    )
{%- endmacro %}
