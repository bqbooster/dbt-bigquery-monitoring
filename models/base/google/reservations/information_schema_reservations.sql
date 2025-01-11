{{ config(materialization=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservations -#}

SELECT ddl, project_id, project_number, reservation_name, ignore_idle_slots, slot_capacity, target_job_concurrency, autoscale, edition
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATIONS`
