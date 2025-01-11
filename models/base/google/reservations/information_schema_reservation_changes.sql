{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservation-changes -#}

SELECT change_timestamp, project_id, project_number, reservation_name, ignore_idle_slots, action, slot_capacity, user_email, target_job_concurrency, autoscale, edition
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATION_CHANGES`
