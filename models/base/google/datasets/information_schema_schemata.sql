{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata -#}

SELECT
catalog_name,
schema_name,
schema_owner,
creation_time,
last_modified_time,
location,
ddl,
default_collation_name
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
