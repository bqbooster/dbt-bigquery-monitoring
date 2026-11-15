{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-capacity-commitments -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.CAPACITY_COMMITMENTS view,
you need the bigquery.capacityCommitments.list Identity and Access Management (IAM)
permission for the project.
Each of the following predefined IAM roles includes the required
permission:
roles/bigquery.resourceAdmin
roles/bigquery.resourceEditor
roles/bigquery.resourceViewer
roles/bigquery.user
roles/bigquery.admin
For more information about BigQuery permissions, see
Access control with IAM  -#}

SELECT
ddl,
project_id,
project_number,
capacity_commitment_id,
commitment_plan,
state,
slot_count,
edition,
is_flat_rate,
renewal_plan
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`CAPACITY_COMMITMENTS`
