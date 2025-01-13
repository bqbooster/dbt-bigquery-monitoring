{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-object-privileges -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.OBJECT_PRIVILEGES view, you need following
Identity and Access Management (IAM) permissions:
bigquery.datasets.get for datasets.
bigquery.tables.getIamPolicy for tables and views.
For more information about BigQuery permissions, see
Access control with IAM. -#}

SELECT
object_catalog,
object_schema,
object_name,
object_type,
privilege_type,
grantee
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`OBJECT_PRIVILEGES`
