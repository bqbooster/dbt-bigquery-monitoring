{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-property-graphs -#}
{# Required role/permissions: 

      To get the permissions that
      you need to query the INFORMATION_SCHEMA.PROPERTY_GRAPHS view,

      ask your administrator to grant you the
    following IAM roles on the project:


BigQuery Metadata Viewer  (roles/bigquery.metadataViewer)
BigQuery Data Viewer  (roles/bigquery.dataViewer)
BigQuery Data Editor  (roles/bigquery.dataEditor)
BigQuery Admin  (roles/bigquery.admin)



  For more information about granting roles, see Manage access to projects, folders, and organizations.




          These predefined roles contain

        the permissions required to query the INFORMATION_SCHEMA.PROPERTY_GRAPHS view. To see the exact permissions that are
        required, expand the Required permissions section:



Required permissions
The following permissions are required to query the INFORMATION_SCHEMA.PROPERTY_GRAPHS view:


bigquery.propertyGraphs.get


bigquery.propertyGraphs.list



        You might also be able to get
          these permissions
        with custom roles or
        other predefined roles.
      For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
property_graph_catalog,
property_graph_schema,
property_graph_name,
property_graph_metadata_json,
ddl
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`PROPERTY_GRAPHS`
