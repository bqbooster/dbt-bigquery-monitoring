{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-write-api-by-folder -#}

SELECT start_timestamp, project_id, project_number, dataset_id, table_id, stream_type, error_code, total_requests, total_rows, total_input_bytes
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`WRITE_API_TIMELINE_BY_FOLDER`
