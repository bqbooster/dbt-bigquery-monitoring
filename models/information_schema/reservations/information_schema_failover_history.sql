{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-failover-history -#}
{# Required role/permissions: 

      To get the permission that
      you need to query the INFORMATION_SCHEMA.FAILOVER_HISTORY view,

      ask your administrator to grant you the
    BigQuery Resource Viewer  (roles/bigquery.resourceViewer) IAM role on the project.






  For more information about granting roles, see Manage access to projects, folders, and organizations.

   -#}

SELECT
project_id,
project_number,
reservation_name,
start_time,
original_primary_location,
from_location,
to_location,
end_time,
failover_mode,
state
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`FAILOVER_HISTORY`
