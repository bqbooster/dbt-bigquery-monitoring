{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-assignments-changes -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.ASSIGNMENT_CHANGES view, you need the
bigquery.reservationAssignments.list Identity and Access Management (IAM) permission for
the project.
Each of the following predefined IAM roles includes the required
permission:
roles/bigquery.resourceAdmin
roles/bigquery.resourceEditor
roles/bigquery.resourceViewer
roles/bigquery.user
roles/bigquery.admin
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
change_timestamp,
project_id,
project_number,
assignment_id,
reservation_name,
job_type,
assignee_id,
assignee_number,
assignee_type,
action,
user_email,
state
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`ASSIGNMENT_CHANGES`
