{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "hour",
      "data_type": "timestamp",
      "copy_partitions": should_use_copy_partitions()
    },
    enabled = enable_gcp_billing_export(),
    partition_expiration_days = var('output_partition_expiration_days')
    )
}}
SELECT
    TIMESTAMP_TRUNC(usage_start_time, HOUR) AS hour,
    sku.description AS compute_type,
    COALESCE(SUM(cost), 0) AS compute_cost,
    {{ currency_to_symbol('currency') }} AS currency_symbol
FROM {{ ref('gcp_billing_export_resource_v1') }}
WHERE
((service.description = 'BigQuery' AND LOWER(sku.description) LIKE '%analysis%')
OR (service.description IN ('BigQuery Reservation API', 'BigQuery BI Engine')))
{% if is_incremental() %}
AND TIMESTAMP_TRUNC(usage_start_time, HOUR) >= TIMESTAMP_SUB(_dbt_max_partition, INTERVAL {{ var('lookback_incremental_billing_window_days') }} DAY)
{% endif %}
GROUP BY ALL
