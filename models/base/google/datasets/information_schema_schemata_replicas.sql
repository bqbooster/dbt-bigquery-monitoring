{{ config(materialization='project_by_project_table') }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-schemata-replicas -#}
{# Required role/permissions: 

      To get the permissions that you need to query the INFORMATION_SCHEMA.SCHEMATA_REPLICAS view,

      ask your administrator to grant you the


  BigQuery Data Viewer  (roles/bigquery.dataViewer) IAM role on the project.




  For more information about granting roles, see Manage access to projects, folders, and organizations.


        You might also be able to get
        the required permissions through custom
        roles or other predefined
        roles.
       -#}

SELECT catalog_name, schema_name, replica_name, location, replica_primary_assigned, replica_primary_assignment_complete, creation_time, creation_complete, replication_time, sync_status
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_REPLICAS`
