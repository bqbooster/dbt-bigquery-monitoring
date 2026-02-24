{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-tables -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.TABLES view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.tables.get
bigquery.tables.list
bigquery.routines.get
bigquery.routines.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.admin
roles/bigquery.dataViewer
roles/bigquery.metadataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
table_catalog,
table_schema,
table_name,
table_type,
managed_table_type,
is_insertable_into,
is_fine_grained_mutations_enabled,
is_typed,
is_change_history_enabled,
creation_time,
base_table_catalog,
base_table_schema,
base_table_name,
snapshot_time_ms,
replica_source_catalog,
replica_source_schema,
replica_source_name,
replication_status,
replication_error,
ddl,
default_collation_name,
sync_status,
upsert_stream_apply_watermark
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`TABLES`
