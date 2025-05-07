{{
   config(
    materialized=materialized_as_view_if_explicit_projects()
    )
}}
WITH
 information_schema_tables AS (
  t.table_catalog AS project_id,
  t.table_schema AS dataset_id,
  t.table_name AS table_id,
  t.default_collation_name,
  t.is_insertable_into,
  t.is_typed,
  t.ddl
  FROM {{ ref('information_schema_tables') }} AS t
 )
SELECT
  *
FROM information_schema_tables
INNER JOIN {{ ref('storage_with_cost') }} AS s USING(project_id, dataset_id, table_id)
