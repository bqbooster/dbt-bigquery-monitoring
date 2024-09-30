{{
   config(
    materialized='table',
    )
}}
SELECT
  TABLE_CATALOG AS project_id,
  TABLE_SCHEMA AS dataset_id,
  table_name AS table_id,
  CASE
    WHEN regexp_contains(partition_id, '^[0-9]{4}$') THEN 'YEAR'
    WHEN regexp_contains(partition_id, '^[0-9]{6}$') THEN 'MONTH'
    WHEN regexp_contains(partition_id, '^[0-9]{8}$') THEN 'DAY'
    WHEN regexp_contains(partition_id, '^[0-9]{10}$') THEN 'HOUR'
    END AS partition_type,
  min(partition_id) AS earliest_partition_id,
  max(partition_id) AS latest_partition_id,
  count(partition_id) AS partition_count,
  sum(total_logical_bytes) AS sum_total_logical_bytes,
  max(last_modified_time) AS max_last_updated_time
FROM {{ ref('information_schema_partitions') }}
GROUP BY ALL
