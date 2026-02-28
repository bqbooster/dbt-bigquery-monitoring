{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-materialized-views -#}
{# Required role/permissions: 

      To get the permissions that
      you need to query the INFORMATION_SCHEMA.MATERIALIZED_VIEWS view,

      ask your administrator to grant you the




      BigQuery Metadata Viewer  (roles/bigquery.metadataViewer)
     IAM role
     on your project or dataset.






  For more information about granting roles, see Manage access to projects, folders, and organizations.




          This predefined role contains

        the permissions required to query the INFORMATION_SCHEMA.MATERIALIZED_VIEWS view. To see the exact permissions that are
        required, expand the Required permissions section:



Required permissions
The following permissions are required to query the INFORMATION_SCHEMA.MATERIALIZED_VIEWS view:


 bigquery.tables.get 


 bigquery.tables.list



        You might also be able to get
          these permissions
        with custom roles or
        other predefined roles.
      Access control with IAM -#}

SELECT
table_catalog,
table_schema,
table_name,
last_refresh_time,
refresh_watermark,
last_refresh_status
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`MATERIALIZED_VIEWS`
