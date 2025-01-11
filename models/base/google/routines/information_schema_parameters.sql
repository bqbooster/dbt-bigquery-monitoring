{{ config(materialization=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-parameters -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.PARAMETERS view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.routines.get
bigquery.routines.list
Each of the following predefined IAM roles includes the
permissions that you need to get routine metadata:
roles/bigquery.admin
roles/bigquery.metadataViewer
roles/bigquery.dataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT specific_catalog, specific_schema, specific_name, ordinal_position, parameter_mode, is_result, parameter_name, data_type, parameter_default, is_aggregate
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`PARAMETERS`
