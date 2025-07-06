{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-storage -#}

SELECT
project_id,
project_number,
table_catalog,
table_schema,
table_name,
creation_time,
total_rows,
total_partitions,
total_logical_bytes,
active_logical_bytes,
long_term_logical_bytes,
current_physical_bytes,
total_physical_bytes,
active_physical_bytes,
long_term_physical_bytes,
time_travel_physical_bytes,
storage_last_modified_time,
deleted,
table_type,
fail_safe_physical_bytes,
last_metadata_index_refresh_time
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE`
