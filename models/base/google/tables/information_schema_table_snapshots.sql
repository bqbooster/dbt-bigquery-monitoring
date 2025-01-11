{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-snapshots -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.TABLE_SNAPSHOTS view, you need the
bigquery.tables.list Identity and Access Management (IAM) permission for the dataset.
The roles/bigquery.metadataViewer predefined role includes the required
permission.For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT table_catalog, table_schema, table_name, base_table_catalog, base_table_schema, base_table_name, snapshot_time
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_SNAPSHOTS`
