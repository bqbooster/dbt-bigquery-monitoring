{{
   config(
    materialized='view',
    )
}}
SELECT
  TIMESTAMP_TRUNC(MINUTE, YEAR) AS year,
  TIMESTAMP_TRUNC(MINUTE, MONTH) AS month,
  TIMESTAMP_TRUNC(MINUTE, DAY) AS day,
  TIMESTAMP_TRUNC(MINUTE, HOUR) AS hour,
  *
FROM {{ ref('compute_cost_per_minute') }}
