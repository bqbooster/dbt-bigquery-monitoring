{{
   config(
    materialized='table',
    )
}}

{%- set option_macros = {
  'bq_region': dbt_bigquery_monitoring_variable_bq_region(),
  'input_gcp_projects': dbt_bigquery_monitoring_variable_input_gcp_projects(),
  'use_flat_pricing': dbt_bigquery_monitoring_variable_use_flat_pricing(),
  'per_billed_tb_price': dbt_bigquery_monitoring_variable_per_billed_tb_price(),
  'free_tb_per_month': dbt_bigquery_monitoring_variable_free_tb_per_month(),
  'hourly_slot_price': dbt_bigquery_monitoring_variable_hourly_slot_price(),
  'active_logical_storage_gb_price': dbt_bigquery_monitoring_variable_active_logical_storage_gb_price(),
  'long_term_logical_storage_gb_price': dbt_bigquery_monitoring_variable_long_term_logical_storage_gb_price(),
  'active_physical_storage_gb_price': dbt_bigquery_monitoring_variable_active_physical_storage_gb_price(),
  'long_term_physical_storage_gb_price': dbt_bigquery_monitoring_variable_long_term_physical_storage_gb_price(),
  'free_storage_gb_per_month': dbt_bigquery_monitoring_variable_free_storage_gb_per_month(),
  'bi_engine_gb_hourly_price': dbt_bigquery_monitoring_variable_bi_engine_gb_hourly_price(),
  'lookback_window_days': dbt_bigquery_monitoring_variable_lookback_window_days(),
  'output_materialization': dbt_bigquery_monitoring_variable_output_materialization(),
  'output_limit_size': dbt_bigquery_monitoring_variable_output_limit_size(),
} %}

{% for option, macro in option_macros.items() %}
SELECT
"{{ option }}" AS option_label,
"{{ macro }}" AS option_value
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
