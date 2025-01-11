{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-routines -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.ROUTINES view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.routines.get
bigquery.routines.list
Each of the following predefined IAM roles includes the
permissions that you need in order to get routine metadata:
roles/bigquery.admin
roles/bigquery.metadataViewer
roles/bigquery.dataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT specific_catalog, specific_schema, specific_name, routine_catalog, routine_schema, routine_name, routine_type, data_type, routine_body, routine_definition, external_language, is_deterministic, security_type, created, last_altered, ddl, connection
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ROUTINES`
