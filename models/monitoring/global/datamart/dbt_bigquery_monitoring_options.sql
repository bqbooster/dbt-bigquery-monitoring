{{
   config(
    materialized='table',
    )
}}

{%- set options = [
  'bq_region',
  'input_gcp_projects',
  'use_flat_pricing',
  'per_billed_tb_price',
  'free_tb_per_month',
  'hourly_slot_price',
  'active_logical_storage_gb_price',
  'long_term_logical_storage_gb_price',
  'active_physical_storage_gb_price',
  'long_term_physical_storage_gb_price',
  'free_storage_gb_per_month',
  'bi_engine_gb_hourly_price',
  'lookback_window_days',
  'output_materialization',
  'output_limit_size',
] %}

{% for option in options %}
SELECT
"{{ option }}" AS option_label,
"{{ var(option) }}" AS option_value
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
