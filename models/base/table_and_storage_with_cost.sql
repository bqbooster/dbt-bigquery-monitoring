{{
   config(
    materialized='view'
    )
}}
WITH base AS (
SELECT
  t.is_insertable_into,
  t.is_typed,
  t.ddl,
  t.base_table_catalog AS project_id,
  t.base_table_schema AS dataset_id,
  t.base_table_name AS table_id,
  t.default_collation_name,
  s.project_number,
  s.creation_time,
  s.deleted,
  s.storage_last_modified_time,
  s.total_rows,
  s.total_partitions,
  s.total_logical_bytes,
  s.active_logical_bytes,
  s.long_term_logical_bytes,
  s.total_physical_bytes,
  s.active_physical_bytes,
  s.long_term_physical_bytes,
  s.time_travel_physical_bytes,
  s.table_type
  FROM {{ ref('information_schema_tables') }} t
  INNER JOIN {{ ref('information_schema_table_storage') }} AS s ON
    t.table_name = s.table_name AND t.table_schema = s.table_schema
),

base_with_enriched_fields AS (
SELECT
  *,
  active_logical_bytes / POW(1024, 3) * {{ var('active_logical_storage_gb_price') }} AS active_logical_bytes_cost,
  long_term_logical_bytes / POW(1024, 3) * {{ var('long_term_logical_storage_gb_price') }} AS long_term_logical_bytes_cost,
  active_physical_bytes / POW(1024, 3) * {{ var('active_physical_storage_gb_price') }} AS active_physical_bytes_cost,
  long_term_physical_bytes / POW(1024, 3) * {{ var('long_term_physical_storage_gb_price') }} AS long_term_physical_bytes_cost,
  time_travel_physical_bytes / POW(1024, 3) * {{ var('active_physical_storage_gb_price') }} AS time_travel_physical_bytes_cost
FROM base
)

SELECT
  *,
  {{ sharded_table_merger("table_id") }} factored_table_id,
  total_logical_bytes / POW(1024, 4) AS total_tb,
  active_logical_bytes_cost + long_term_logical_bytes_cost + active_physical_bytes_cost + long_term_physical_bytes_cost + time_travel_physical_bytes_cost AS storage_cost
FROM base_with_enriched_fields
