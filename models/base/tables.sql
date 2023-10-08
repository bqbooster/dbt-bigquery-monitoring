{{
   config(
    materialized='view'
    )
}}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-tables -#}
WITH base AS (
  {% for project in project_list() -%}
SELECT
  table_catalog,
  table_schema,
  table_name,
  table_type,
  is_insertable_into,
  is_typed,
  creation_time,
  ddl,
  base_table_catalog,
  base_table_schema,
  base_table_name,
  default_collation_name
FROM
  `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLES`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
)

SELECT *
FROM base
