{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservation-timeline -#}

SELECT
autoscale,
edition,
ignore_idle_slots,
labels,
period_start,
project_id,
project_number,
reservation_id,
reservation_name,
slots_assigned,
slots_max_assigned,
max_slots,
scaling_mode
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`RESERVATIONS_TIMELINE`
