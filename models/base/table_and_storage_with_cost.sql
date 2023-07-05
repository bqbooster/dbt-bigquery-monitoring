{{
   config(
    materialized='view'
    )
}}
WITH base AS (
  {% for project in var('input_gcp_projects').split(',') -%}
SELECT
  t.is_insertable_into,
  t.is_typed,
  t.ddl,
  t.base_table_catalog,
  t.base_table_schema AS dataset_id,
  t.base_table_name AS table_id,
  t.default_collation_name,
  s.PROJECT_ID,
  s.PROJECT_NUMBER,
  s.TABLE_SCHEMA,
  s.TABLE_NAME,
  s.CREATION_TIME,
  s.DELETED,
  s.STORAGE_LAST_MODIFIED_TIME,
  s.TOTAL_ROWS,
  s.TOTAL_PARTITIONS,
  s.TOTAL_LOGICAL_BYTES,
  s.ACTIVE_LOGICAL_BYTES,
  s.LONG_TERM_LOGICAL_BYTES,
  s.TOTAL_PHYSICAL_BYTES,
  s.ACTIVE_PHYSICAL_BYTES,
  s.LONG_TERM_PHYSICAL_BYTES,
  s.TIME_TRAVEL_PHYSICAL_BYTES,
  s.TABLE_TYPE
  FROM
  `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLES` AS t
  INNER JOIN
  `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE` AS s ON
    t.table_name = s.table_name AND t.table_schema = s.table_schema
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
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
