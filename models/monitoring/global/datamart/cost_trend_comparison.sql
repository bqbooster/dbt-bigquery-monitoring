{{
   config(
    materialized='view',
    )
}}
{# Daily cost with rolling averages and week-over-week comparison for anomaly detection dashboards #}
WITH daily AS (
  SELECT
    day,
    cost_category,
    SUM(cost) AS daily_cost
  FROM {{ ref('daily_spend') }}
  GROUP BY day, cost_category
),

with_rolling AS (
  SELECT
    day,
    cost_category,
    daily_cost,
    AVG(daily_cost) OVER (
      PARTITION BY cost_category
      ORDER BY UNIX_SECONDS(CAST(day AS TIMESTAMP)) ASC
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7d_avg_cost,
    AVG(daily_cost) OVER (
      PARTITION BY cost_category
      ORDER BY UNIX_SECONDS(CAST(day AS TIMESTAMP)) ASC
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_avg_cost,
    LAG(daily_cost, 7) OVER (
      PARTITION BY cost_category
      ORDER BY day ASC
    ) AS cost_same_day_last_week
  FROM daily
)

SELECT
  day,
  cost_category,
  ROUND(daily_cost, 2) AS daily_cost,
  ROUND(rolling_7d_avg_cost, 2) AS rolling_7d_avg_cost,
  ROUND(rolling_30d_avg_cost, 2) AS rolling_30d_avg_cost,
  ROUND(cost_same_day_last_week, 2) AS cost_same_day_last_week,
  ROUND(
    SAFE_DIVIDE(daily_cost - cost_same_day_last_week, cost_same_day_last_week) * 100,
    1
  ) AS wow_pct_change,
  ROUND(
    SAFE_DIVIDE(daily_cost - rolling_7d_avg_cost, rolling_7d_avg_cost) * 100,
    1
  ) AS pct_deviation_from_7d_avg
FROM with_rolling
ORDER BY day DESC, cost_category ASC
LIMIT {{ dbt_bigquery_monitoring_variable_output_limit_size() }}
