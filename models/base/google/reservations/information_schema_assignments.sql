{{ config(materialization=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-assignments -#}

SELECT ddl, project_id, project_number, assignment_id, reservation_name, job_type, assignee_id, assignee_number, assignee_type
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ASSIGNMENTS`
