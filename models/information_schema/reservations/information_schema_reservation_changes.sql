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
primarylocation,
secondarylocation,
originalprimarylocation,
labels,
max_slots,
scaling_mode
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATION_CHANGES`
