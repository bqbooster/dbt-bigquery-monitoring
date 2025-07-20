{{ config(materialized=dbt_bigquery_monitoring_materialization(), tags=["dbt-bigquery-monitoring-information-schema-by-organization"]) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-indexes-by-organization -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.SEARCH_INDEXES_BY_ORGANIZATION view, you need
the following Identity and Access Management (IAM) permissions for your organization:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.admin
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
This schema view is only available to users with defined
Google Cloud organizations.For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
project_id,
project_number,
index_catalog,
index_schema,
table_name,
index_name,
index_status,
index_status_details,
use_background_reservation
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`SEARCH_INDEXES_BY_ORGANIZATION`
