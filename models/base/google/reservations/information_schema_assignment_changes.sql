{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-assignments-changes -#}

SELECT change_timestamp, project_id, project_number, assignment_id, reservation_name, job_type, assignee_id, assignee_number, assignee_type, action, user_email, state
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ASSIGNMENT_CHANGES`
