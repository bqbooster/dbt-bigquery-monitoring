{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-schemata-replicas -#}
{# Required role/permissions: 

      To get the permission that
      you need to query the INFORMATION_SCHEMA.SCHEMATA_REPLICAS view,

      ask your administrator to grant you the
    BigQuery Data Viewer  (roles/bigquery.dataViewer) IAM role on the project.






  For more information about granting roles, see Manage access to projects, folders, and organizations.

   -#}

SELECT
catalog_name,
schema_name,
replica_name,
location,
replica_primary_assigned,
replica_primary_assignment_complete,
creation_time,
creation_complete,
replication_time,
sync_status,
replica_primary_assignment_time,
replica_primary_assignment_completion_time
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`SCHEMATA_REPLICAS`
