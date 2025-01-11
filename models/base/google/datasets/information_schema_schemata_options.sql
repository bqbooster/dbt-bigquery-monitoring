{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata-options -#}

SELECT catalog_name, schema_name, option_name, option_type, option_value
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_OPTIONS`
