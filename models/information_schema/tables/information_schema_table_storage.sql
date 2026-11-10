{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-storage -#}
{# Required role/permissions: 

      To get the permissions that
      you need to query the INFORMATION_SCHEMA.TABLE_STORAGE view,

      ask your administrator to grant you the
    BigQuery Metadata Viewer  (roles/bigquery.metadataViewer) IAM role on the project.






  For more information about granting roles, see Manage access to projects, folders, and organizations.




          This predefined role contains

        the permissions required to query the INFORMATION_SCHEMA.TABLE_STORAGE view. To see the exact permissions that are
        required, expand the Required permissions section:



Required permissions
The following permissions are required to query the INFORMATION_SCHEMA.TABLE_STORAGE view:


bigquery.tables.get


bigquery.tables.list



        You might also be able to get
          these permissions
        with custom roles or
        other predefined roles.
       -#}

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
managed_table_type,
fail_safe_physical_bytes,
last_metadata_index_refresh_time,
table_deletion_reason,
table_deletion_time
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE`
