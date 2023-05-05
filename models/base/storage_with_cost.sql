{{
   config(
    materialized='view'
    )
}}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-tables -#}
WITH base AS (
  {% for project in var('input_gcp_projects').split(',') -%}
SELECT
  PROJECT_ID,
  PROJECT_NUMBER,
  TABLE_SCHEMA,
  TABLE_NAME,
  CREATION_TIME,
  DELETED,
  STORAGE_LAST_MODIFIED_TIME,
  TOTAL_ROWS,
  TOTAL_PARTITIONS,
  TOTAL_LOGICAL_BYTES,
  ACTIVE_LOGICAL_BYTES,
  LONG_TERM_LOGICAL_BYTES,
  TOTAL_PHYSICAL_BYTES,
  ACTIVE_PHYSICAL_BYTES,
  LONG_TERM_PHYSICAL_BYTES,
  TIME_TRAVEL_PHYSICAL_BYTES,
  TABLE_TYPE
FROM
  `{{ project | trim }}`.`region-{{ var('bq_region') }}`.``INFORMATION_SCHEMA``.`TABLE_STORAGE`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
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
  total_logical_bytes / POW(1024, 4) AS total_tb
FROM base_with_enriched_fields
