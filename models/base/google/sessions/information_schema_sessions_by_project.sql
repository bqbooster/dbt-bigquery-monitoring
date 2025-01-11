{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-sessions-by-project -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.SESSIONS_BY_PROJECT view, you need
the bigquery.jobs.listAll Identity and Access Management (IAM) permission for the project.
Each of the following predefined IAM roles includes the
required permission:
Project Owner
BigQuery Admin
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT creation_time, expiration_time, is_active, last_modified_time, project_id, project_number, session_id, user_email
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SESSIONS_BY_PROJECT`
