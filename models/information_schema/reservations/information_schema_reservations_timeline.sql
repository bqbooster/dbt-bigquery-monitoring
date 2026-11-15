{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservation-timeline -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.RESERVATIONS_TIMELINE view, you need
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
autoscale,
edition,
ignore_idle_slots,
labels,
{%- if dbt_bigquery_monitoring_variable_enable_reservation_group_path() %}reservation_group_path,{%- endif %}
period_start,
per_second_details,
project_id,
project_number,
reservation_id,
reservation_name,
slot_capacity,
slots_assigned,
slots_max_assigned,
max_slots,
scaling_mode,
period_autoscale_slot_seconds,
is_creation_region
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`RESERVATIONS_TIMELINE`
