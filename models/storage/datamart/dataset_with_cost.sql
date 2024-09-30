{{
   config(
    materialized='table',
    )
}}
WITH base AS (
SELECT
  s.table_catalog AS project_id,
  s.table_schema AS dataset_id,
  s.project_number,
  MAX(s.storage_last_modified_time) AS storage_last_modified_time,
  SUM(s.total_rows) AS total_rows,
  SUM(s.total_partitions) AS total_partitions,
  SUM(s.total_logical_bytes) AS total_logical_bytes,
  SUM(IF(deleted = false, s.active_logical_bytes, 0)) AS active_logical_bytes,
  SUM(IF(deleted = false, s.long_term_logical_bytes, 0)) AS long_term_logical_bytes,
  SUM(s.total_physical_bytes) AS total_physical_bytes,
  SUM(s.active_physical_bytes) AS active_physical_bytes,
  SUM(s.long_term_physical_bytes) AS long_term_physical_bytes,
  SUM(s.time_travel_physical_bytes) AS time_travel_physical_bytes,
  SUM(s.fail_safe_physical_bytes) AS fail_safe_physical_bytes,
  FROM {{ ref('information_schema_table_storage') }} AS s
  GROUP BY ALL
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

base_with_forecast AS (
SELECT
  *,
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
)

SELECT
  *,
  (logical_cost_monthly_forecast - physical_cost_monthly_forecast) > 0 AS prefer_physical_pricing_model,
  ABS(logical_cost_monthly_forecast - physical_cost_monthly_forecast) AS storage_pricing_model_difference
FROM base_with_forecast
