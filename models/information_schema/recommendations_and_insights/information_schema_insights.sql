{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-insights -#}

SELECT
insight_id,
insight_type,
subtype,
project_id,
project_number,
description,
last_updated_time,
category,
target_resources,
state,
severity,
associated_recommendation_ids,
additional_details
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`INSIGHTS`
