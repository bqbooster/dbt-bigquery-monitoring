{{
   config(
    materialized='incremental',
    incremental_strategy = 'insert_overwrite',
    on_schema_change='append_new_columns',
    partition_by={
      "field": "hour",
      "data_type": "timestamp",
      "copy_partitions": dbt_bigquery_monitoring_variable_use_copy_partitions()
    },
    enabled = dbt_bigquery_monitoring_variable_enable_gcp_billing_export(),
    partition_expiration_days = dbt_bigquery_monitoring_variable_output_partition_expiration_days()
    )
}}
SELECT
    TIMESTAMP_TRUNC(usage_start_time, HOUR) AS hour,
    sku.description AS storage_type,
    COALESCE(SUM(cost), 0) AS storage_cost,
    {{ currency_to_symbol('currency') }} AS currency_symbol
FROM {{ ref('gcp_billing_export_resource_v1') }}
WHERE
(service.description LIKE '%BigQuery%'
AND LOWER(sku.description) LIKE '%storage%')
{% if is_incremental() %}
AND TIMESTAMP_TRUNC(usage_start_time, HOUR) >= TIMESTAMP_SUB(_dbt_max_partition, INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_incremental_billing_window_days() }} DAY)
{% endif %}
GROUP BY ALL
