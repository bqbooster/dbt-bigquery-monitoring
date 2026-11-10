{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-insights -#}
{# Required role/permissions: To view insights with the INFORMATION_SCHEMA.INSIGHTS view, you
must have the required permissions for the corresponding recommender. The
INFORMATION_SCHEMA.INSIGHTS view only returns insights from recommendations
that you have permission to view.Ask your administrator to grant access to view insights. To see the
required permissions for each recommender, see the following:
Partition & cluster recommender permissions
Materialized view recommendations permissions
Role recommendations for datasets permissions
 -#}

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
