{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-bi-capacities -#}

SELECT project_id, project_number, bi_capacity_name, size, preferred_tables
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`BI_CAPACITIES`
