{{
   config(
    materialized='view',
    )
}}

SELECT
  TIMESTAMP_TRUNC(HOUR, YEAR) AS year,
  TIMESTAMP_TRUNC(HOUR, MONTH) AS month,
  TIMESTAMP_TRUNC(HOUR, DAY) AS day,
  *
FROM {{ ref('compute_cost_per_hour') }}
