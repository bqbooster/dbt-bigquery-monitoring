{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata-links -#}

SELECT
catalog_name,
schema_name,
linked_schema_catalog_number,
linked_schema_catalog_name,
linked_schema_name,
linked_schema_creation_time,
linked_schema_org_display_name,
shared_asset_id,
link_type
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`SCHEMATA_LINKS`
