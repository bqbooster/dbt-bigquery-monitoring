{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-bi-capacity-changes -#}

SELECT
change_timestamp,
project_id,
project_number,
bi_capacity_name,
size,
user_email,
preferred_tables
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`BI_CAPACITY_CHANGES`
