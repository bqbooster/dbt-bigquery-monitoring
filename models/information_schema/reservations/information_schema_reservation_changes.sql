{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservation-changes -#}

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
reservation_group_path,
max_slots,
scaling_mode
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`RESERVATION_CHANGES`
