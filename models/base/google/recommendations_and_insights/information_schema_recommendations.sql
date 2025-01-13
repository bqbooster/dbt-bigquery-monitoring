{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-recommendations -#}

SELECT
recommendation_id,
recommender,
subtype,
project_id,
project_number,
description,
last_updated_time,
target_resources,
state,
primary_impact,
priority,
associated_insight_ids,
additional_details
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RECOMMENDATIONS`
