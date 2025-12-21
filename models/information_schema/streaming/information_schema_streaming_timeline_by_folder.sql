{{ config(materialized=dbt_bigquery_monitoring_materialization(), enabled=false, tags=["dbt-bigquery-monitoring-information-schema-by-folder"]) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-streaming-by-folder -#}

SELECT
start_timestamp,
folder_numbers,
project_id,
project_number,
dataset_id,
table_id,
error_code,
total_requests,
total_rows,
total_input_bytes
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`STREAMING_TIMELINE_BY_FOLDER`
