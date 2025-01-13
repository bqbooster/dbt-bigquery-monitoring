{{
   config(
    materialized='view',
    )
}}
SELECT
  *,
  CASE partition_type
    WHEN 'YEAR' THEN PARSE_TIMESTAMP('%Y', earliest_partition_id)
    WHEN 'MONTH' THEN PARSE_TIMESTAMP('%Y%m', earliest_partition_id)
    WHEN 'DAY' THEN PARSE_TIMESTAMP('%Y%m%d', earliest_partition_id)
    WHEN 'HOUR' THEN PARSE_TIMESTAMP('%Y%m%d%H', earliest_partition_id)
    END AS earliest_partition_time,
  CASE partition_type
    WHEN 'YEAR' THEN PARSE_TIMESTAMP('%Y', latest_partition_id)
    WHEN 'MONTH' THEN PARSE_TIMESTAMP('%Y%m', latest_partition_id)
    WHEN 'DAY' THEN PARSE_TIMESTAMP('%Y%m%d', latest_partition_id)
    WHEN 'HOUR' THEN PARSE_TIMESTAMP('%Y%m%d%H', latest_partition_id)
    END AS latest_partition_time
FROM {{ ref('stg_partitions_monitoring') }}
