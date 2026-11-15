{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservation-changes -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.RESERVATION_CHANGES view, you need
the bigquery.reservations.list Identity and Access Management (IAM) permission on the
project.
Each of the following predefined IAM roles includes the required
permission:
BigQuery Resource Admin (roles/bigquery.resourceAdmin)
BigQuery Resource Editor (roles/bigquery.resourceEditor)
BigQuery Resource Viewer (roles/bigquery.resourceViewer)
BigQuery User (roles/bigquery.user)
BigQuery Admin (roles/bigquery.admin)
For more information about BigQuery permissions, see
BigQuery IAM roles and permissions. -#}

SELECT
change_timestamp,
project_id,
project_number,
reservation_name,
ignore_idle_slots,
action,
slot_capacity,
user_email,
target_job_concurrency,
autoscale,
edition,
primary_location,
secondary_location,
original_primary_location,
labels,
{%- if dbt_bigquery_monitoring_variable_enable_reservation_group_path() %}reservation_group_path,{%- endif %}
max_slots,
scaling_mode
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`RESERVATION_CHANGES`
