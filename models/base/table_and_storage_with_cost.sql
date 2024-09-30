{{
   config(
    materialized=materialized_as_view_if_explicit_projects()
    )
}}
WITH base AS (
SELECT
  t.is_insertable_into,
  t.is_typed,
  t.ddl,
  t.table_catalog AS project_id,
  t.table_schema AS dataset_id,
  t.table_name AS table_id,
  t.default_collation_name,
  s.project_number,
  s.creation_time,
  s.deleted,
  s.storage_last_modified_time,
  s.total_rows,
  s.total_partitions,
  s.total_logical_bytes,
  IF(deleted=false, s.active_logical_bytes, 0) active_logical_bytes,
  IF(deleted=false, s.long_term_logical_bytes, 0) long_term_logical_bytes,
  s.total_physical_bytes,
  s.active_physical_bytes,
  s.long_term_physical_bytes,
  s.time_travel_physical_bytes,
  s.fail_safe_physical_bytes,
  s.table_type
  FROM {{ ref('information_schema_tables') }} t
  INNER JOIN {{ ref('information_schema_table_storage') }} AS s ON
    t.table_name = s.table_name AND t.table_schema = s.table_schema
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
  {{ sharded_table_merger("table_id") }} factored_table_id,
  total_logical_bytes / POW(1024, 4) AS total_logical_tb,
  total_physical_bytes / POW(1024, 4) AS total_physical_tb,
  (active_logical_bytes_cost + long_term_logical_bytes_cost) AS logical_cost_monthly_forecast,
  (active_physical_bytes_cost + long_term_physical_bytes_cost) AS physical_cost_monthly_forecast,
  ((active_physical_bytes_cost - time_travel_physical_bytes_cost - fail_safe_physical_bytes_cost) + long_term_physical_bytes_cost) AS physical_cost_monthly_forecast_with_zero_time_travel_and_fail_safe,
  SAFE_DIVIDE(time_travel_physical_bytes, active_physical_bytes) as time_travel_per_active_byte_ratio,
  SAFE_DIVIDE(fail_safe_physical_bytes, active_physical_bytes) as fail_safe_per_active_byte_ratio,
  SAFE_DIVIDE(active_logical_bytes, (active_physical_bytes - time_travel_physical_bytes)) AS active_compression_ratio,
  SAFE_DIVIDE(long_term_logical_bytes, long_term_physical_bytes) AS long_term_compression_ratio,

FROM base_with_enriched_fields
)
SELECT
  *,
  (logical_cost_monthly_forecast - physical_cost_monthly_forecast) > 0 AS prefer_physical_pricing_model,
  ABS(logical_cost_monthly_forecast - physical_cost_monthly_forecast) AS storage_pricing_model_difference
FROM base_with_forecast
