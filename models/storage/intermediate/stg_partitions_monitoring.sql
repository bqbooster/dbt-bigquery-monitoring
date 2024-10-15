{{
   config(
    materialized='table',
    )
}}
WITH partition_expirations AS (
  SELECT
table_catalog,
table_schema,
table_name,
CAST(option_value AS INT64) AS partition_expiration_days
  FROM {{ ref('information_schema_table_options') }}
  WHERE option_name = 'partition_expiration_days'
)

SELECT
  p.TABLE_CATALOG AS project_id,
  p.TABLE_SCHEMA AS dataset_id,
  p.table_name AS table_id,
  CASE
    WHEN REGEXP_CONTAINS(p.partition_id, '^[0-9]{4}$') THEN 'YEAR'
    WHEN REGEXP_CONTAINS(p.partition_id, '^[0-9]{6}$') THEN 'MONTH'
    WHEN REGEXP_CONTAINS(p.partition_id, '^[0-9]{8}$') THEN 'DAY'
    WHEN REGEXP_CONTAINS(p.partition_id, '^[0-9]{10}$') THEN 'HOUR'
    END AS partition_type,
  e.partition_expiration_days,
  MIN(p.partition_id) AS earliest_partition_id,
  MAX(p.partition_id) AS latest_partition_id,
  COUNT(p.partition_id) AS partition_count,
  SUM(p.total_logical_bytes) AS sum_total_logical_bytes,
  MAX(p.last_modified_time) AS max_last_updated_time
FROM {{ ref('information_schema_partitions') }} AS p
INNER JOIN partition_expirations AS e USING (table_catalog, table_schema, table_name)
GROUP BY ALL
