{{
   config(
    materialized=materialized_as_view_if_explicit_projects()
    )
}}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-tables -#}
WITH base AS (
SELECT
  project_id,
  project_number,
  table_schema AS dataset_id,
  table_name AS table_id,
  creation_time,
  deleted,
  storage_last_modified_time,
  total_rows,
  total_partitions,
  total_logical_bytes,
  IF(s.deleted = false, active_logical_bytes, 0) AS active_logical_bytes,
  IF(s.deleted = false, long_term_logical_bytes, 0) AS long_term_logical_bytes,
  total_physical_bytes,
  active_physical_bytes,
  long_term_physical_bytes,
  time_travel_physical_bytes,
  fail_safe_physical_bytes,
  table_type
FROM
    {{ ref('information_schema_table_storage') }}
),

base_with_enriched_fields AS (
SELECT
  *,
  -- Logical storage costs
  active_logical_bytes / POW(1024, 3) * {{ var('active_logical_storage_gb_price') }} AS active_logical_bytes_cost,
  long_term_logical_bytes / POW(1024, 3) * {{ var('long_term_logical_storage_gb_price') }} AS long_term_logical_bytes_cost,
  -- Physical storage costs
  active_physical_bytes / POW(1024, 3) * {{ var('active_physical_storage_gb_price') }} AS active_physical_bytes_cost,
  time_travel_physical_bytes / POW(1024, 3) * {{ var('active_physical_storage_gb_price') }} AS time_travel_physical_bytes_cost,
  fail_safe_physical_bytes / POW(1024, 3) * {{ var('active_physical_storage_gb_price') }} AS fail_safe_physical_bytes_cost,
  long_term_physical_bytes / POW(1024, 3) * {{ var('long_term_physical_storage_gb_price') }} AS long_term_physical_bytes_cost,
FROM base
),

tables_with_billing_model_cost AS (
  SELECT
  *,
  {{ sharded_table_merger("table_id") }} AS factored_table_id,
  total_logical_bytes / POW(1024, 4) AS total_logical_tb,
  total_physical_bytes / POW(1024, 4) AS total_physical_tb,
  (active_logical_bytes_cost + long_term_logical_bytes_cost) AS logical_cost_monthly_forecast,
  (active_physical_bytes_cost + long_term_physical_bytes_cost) AS physical_cost_monthly_forecast,
  ((active_physical_bytes_cost - time_travel_physical_bytes_cost - fail_safe_physical_bytes_cost) + long_term_physical_bytes_cost) AS physical_cost_monthly_forecast_with_zero_time_travel_and_fail_safe,
  SAFE_DIVIDE(time_travel_physical_bytes, active_physical_bytes) AS time_travel_per_active_byte_ratio,
  SAFE_DIVIDE(fail_safe_physical_bytes, active_physical_bytes) AS fail_safe_per_active_byte_ratio,
  SAFE_DIVIDE(active_logical_bytes, (active_physical_bytes - time_travel_physical_bytes)) AS active_compression_ratio,
  SAFE_DIVIDE(long_term_logical_bytes, long_term_physical_bytes) AS long_term_compression_ratio,
  FROM base_with_enriched_fields
),

with_dataset_options AS (
  SELECT
    *,
    storage_billing_model,
    IF(storage_billing_model = "LOGICAL", logical_cost_monthly_forecast, physical_cost_monthly_forecast) AS cost_monthly_forecast,
    IF(logical_cost_monthly_forecast > physical_cost_monthly_forecast, "PHYSICAL", "LOGICAL") AS optimal_storage_billing_model
    ABS(logical_cost_monthly_forecast - physical_cost_monthly_forecast) AS storage_pricing_model_difference
  FROM tables_with_billing_model_cost
  JOIN {{ ref('dataset_options') }} USING (project_id, dataset_id)
)

SELECT
  *,
  IF(storage_billing_model != optimal_storage_billing_model, storage_pricing_model_difference, NULL) AS potential_savings
FROM with_dataset_options
