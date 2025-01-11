{{ config(materialization=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-shared-dataset-usage -#}

SELECT project_id, dataset_id, table_id, data_exchange_id, listing_id, job_start_time, job_end_time, job_id, job_project_number, job_location, linked_project_number, linked_dataset_id, subscriber_org_number, subscriber_org_display_name, num_rows_processed, total_bytes_processed
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SHARED_DATASET_USAGE`
