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
  active_logical_bytes,
  long_term_logical_bytes,
  total_physical_bytes,
  active_physical_bytes,
  long_term_physical_bytes,
  time_travel_physical_bytes,
  table_type
FROM
    {{ ref('information_schema_table_storage') }}
),

base_with_enriched_fields AS (
SELECT
  *,
  `ACTIVE_LOGICAL_BYTES` / POW(1024, 3) * {{ var('active_logical_storage_gb_price') }} AS active_logical_bytes_cost,
  `LONG_TERM_LOGICAL_BYTES` / POW(1024, 3) * {{ var('long_term_logical_storage_gb_price') }} AS long_term_logical_bytes_cost,
  `ACTIVE_PHYSICAL_BYTES` / POW(1024, 3) * {{ var('active_physical_storage_gb_price') }} AS active_physical_bytes_cost,
  `LONG_TERM_PHYSICAL_BYTES` / POW(1024, 3) * {{ var('long_term_physical_storage_gb_price') }} AS long_term_physical_bytes_cost,
  `TIME_TRAVEL_PHYSICAL_BYTES` / POW(1024, 3) * {{ var('active_physical_storage_gb_price') }} AS time_travel_physical_bytes_cost,
FROM base
)

SELECT
  *,
  total_logical_bytes / POW(1024, 4) AS total_tb,
  active_logical_bytes_cost + long_term_logical_bytes_cost + active_physical_bytes_cost + long_term_physical_bytes_cost + time_travel_physical_bytes_cost AS storage_cost
FROM base_with_enriched_fields
