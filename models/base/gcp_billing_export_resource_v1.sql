{{
   config(
    materialized = "ephemeral",
    enabled = enable_gcp_billing_export()
    )
}}
SELECT
  billing_account_id,
  invoice,
  cost_type,
  service,
  sku,
  usage_start_time,
  usage_end_time,
  project,
  labels,
  system_labels,
  location,
  cost,
  currency,
  currency_conversion_rate,
  usage,
  credits,
  adjustment_info,
  export_time,
  tags,
  cost_at_list,
  transaction_type,
  seller_name
FROM
 `{{ var('gcp_billing_export_storage_project') }}.{{ var('gcp_billing_export_dataset') }}.{{ var('gcp_billing_export_table') }}`
