{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservations -#}

SELECT
ddl,
project_id,
project_number,
reservation_name,
ignore_idle_slots,
slot_capacity,
target_job_concurrency,
autoscale,
edition,
primary_location,
secondary_location,
original_primary_location,
labels,
{%- if dbt_bigquery_monitoring_variable_enable_reservation_group_path() %}
reservation_group_path,
{%- endif %}
max_slots,
scaling_mode
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`RESERVATIONS`
