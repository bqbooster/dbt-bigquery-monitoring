{#- format input milliseconds field into a human readable string -#}
{% macro milliseconds_to_readable_time_udf() -%}
CREATE TEMP FUNCTION second_str(ms INT64, maxUnits INT64, result ARRAY<STRING>)
RETURNS ARRAY<STRING>
AS ((
  SELECT
    (IF(seconds > 0 AND ARRAY_LENGTH(result) < maxUnits,
      ARRAY_CONCAT(result, [CONCAT(CAST(seconds AS STRING), ' second', IF(seconds > 1, 's', ''))]),
      result
    ))
  FROM (
    SELECT MOD(ms, 1000) ms, maxUnits, DIV(ms, 1000) AS seconds, result
  )
));

CREATE TEMP FUNCTION minute_str(ms INT64, maxUnits INT64, result ARRAY<STRING>)
RETURNS ARRAY<STRING>
AS ((
  SELECT
    second_str(ms, maxUnits, IF(minutes > 0 AND ARRAY_LENGTH(result) < maxUnits,
      ARRAY_CONCAT(result, [CONCAT(CAST(minutes AS STRING), ' minute', IF(minutes > 1, 's', ''))]),
      result
    ))
  FROM (
    SELECT MOD(ms, 1000 * 60) ms, maxUnits, DIV(ms, 1000 * 60) AS minutes, result
  )
));

CREATE TEMP FUNCTION hour_str(ms INT64, maxUnits INT64, result ARRAY<STRING>)
RETURNS ARRAY<STRING>
AS ((
  SELECT
    minute_str(ms, maxUnits, IF(hours > 0 AND ARRAY_LENGTH(result) < maxUnits,
      ARRAY_CONCAT(result, [CONCAT(CAST(hours AS STRING), ' hour', IF(hours > 1, 's', ''))]),
      result
    ))
  FROM (
    SELECT MOD(ms, 1000 * 60 * 60) ms, maxUnits, DIV(ms, 1000 * 60 * 60) AS hours, result
  )
));

CREATE TEMP FUNCTION day_str(ms INT64, maxUnits INT64, result ARRAY<STRING>)
RETURNS ARRAY<STRING>
AS ((
  SELECT
    hour_str(ms, maxUnits, IF(days > 0 AND ARRAY_LENGTH(result) < maxUnits,
      ARRAY_CONCAT(result, [CONCAT(CAST(days AS STRING), ' day', IF(days > 1, 's', ''))]),
      result
    ))
  FROM (
    SELECT MOD(ms, 1000 * 60 * 60 * 24) ms, maxUnits, DIV(ms, 1000 * 60 * 60 * 24) AS days, result
  )
));

CREATE TEMP FUNCTION month_str(ms INT64, maxUnits INT64, result ARRAY<STRING>)
RETURNS ARRAY<STRING>
AS ((
  SELECT
    day_str(ms, maxUnits, IF(months > 0 AND ARRAY_LENGTH(result) < maxUnits,
      ARRAY_CONCAT(result, [CONCAT(CAST(months AS STRING), ' month', IF(months > 1, 's', ''))]),
      result
    ))
  FROM (
    SELECT MOD(ms, 1000 * 60 * 60 * 24 * 30) ms, maxUnits, DIV(ms, 1000 * 60 * 60 * 24 * 30) AS months, result
  )
));

CREATE TEMP FUNCTION year_str(ms INT64, maxUnits INT64, result ARRAY<STRING>)
RETURNS ARRAY<STRING>
AS ((
  SELECT
    month_str(ms, maxUnits, IF(years > 0 AND ARRAY_LENGTH(result) < maxUnits,
      ARRAY_CONCAT(result, [CONCAT(CAST(years AS STRING), ' year', IF(years > 1, 's', ''))]),
      result
    ))
  FROM (
    SELECT MOD(ms, 1000 * 60 * 60 * 24 * 30 * 12) ms, maxUnits, DIV(ms, 1000 * 60 * 60 * 24 * 30 * 12) AS years, result
  )
));

CREATE TEMP FUNCTION milliseconds_to_readable_time_udf(ms INT64, maxUnits INT64)
RETURNS STRING
AS ((
   select ARRAY_TO_STRING(year_str(ms, maxUnits, []), " ")
));

{%- endmacro %}
