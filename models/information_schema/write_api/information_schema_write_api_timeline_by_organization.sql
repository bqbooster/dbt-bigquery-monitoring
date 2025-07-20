{{ config(materialized=dbt_bigquery_monitoring_materialization(), enabled=false, tags=["dbt-bigquery-monitoring-information-schema-by-organization"]) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-write-api-by-organization -#}

SELECT
start_timestamp,
project_id,
project_number,
dataset_id,
table_id,
stream_type,
error_code,
total_requests,
total_rows,
total_input_bytes
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`WRITE_API_TIMELINE_BY_ORGANIZATION`
