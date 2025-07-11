{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-capacity-commitment-changes -#}

SELECT
change_timestamp,
project_id,
project_number,
capacity_commitment_id,
commitment_plan,
state,
slot_count,
action,
user_email,
commitment_start_time,
commitment_end_time,
failure_status,
renewal_plan,
edition,
is_flat_rate
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`CAPACITY_COMMITMENT_CHANGES`
