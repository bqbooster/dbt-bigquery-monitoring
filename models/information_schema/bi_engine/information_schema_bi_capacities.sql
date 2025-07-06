{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-bi-capacities -#}

SELECT
project_id,
project_number,
bi_capacity_name,
size,
preferred_tables
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`BI_CAPACITIES`
