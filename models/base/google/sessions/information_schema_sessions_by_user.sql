{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-sessions-by-user -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.SESSIONS_BY_USER view, you need
the bigquery.jobs.list Identity and Access Management (IAM) permission for the project.
Each of the following predefined IAM roles includes the
required permission:
Project Viewer
BigQuery User
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
creation_time,
expiration_time,
is_active,
last_modified_time,
project_id,
project_number,
session_id,
user_email
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SESSIONS_BY_USER`
