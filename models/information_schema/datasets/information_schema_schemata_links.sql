{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata-links -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.SCHEMATA_LINKS view, you need the
bigquery.datasets.get Identity and Access Management (IAM) permission at the project
level.Each of the following predefined IAM roles includes the
permissions that you need in order to query the
INFORMATION_SCHEMA.SCHEMATA_LINKS view:
roles/bigquery.admin
roles/bigquery.dataEditor
roles/bigquery.dataOwner
roles/bigquery.dataViewer
For more information about BigQuery permissions, see Access
control with IAM. -#}

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
