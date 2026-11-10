{{ config(materialized=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-constraint-column-usage -#}
{# Required role/permissions: 

      To get the permissions that
      you need to query the INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE view,

      ask your administrator to grant you the
    BigQuery Data Editor  (roles/bigquery.dataEditor) IAM role on your project.






  For more information about granting roles, see Manage access to projects, folders, and organizations.




          This predefined role contains

        the permissions required to query the INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE view. To see the exact permissions that are
        required, expand the Required permissions section:



Required permissions
The following permissions are required to query the INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE view:


                Viewing primary and foreign key definitions:
                  bigquery.tables.get


                Viewing table information schemas:
                  bigquery.tables.list



        You might also be able to get
          these permissions
        with custom roles or
        other predefined roles.
      For more information about IAM roles and permissions in
BigQuery, see
Predefined roles and permissions. -#}


{% set dataset_list = get_dataset_list() %}

WITH base AS (
{%- if dataset_list | length == 0 -%}
  SELECT CAST(NULL AS STRING) AS table_catalog, CAST(NULL AS STRING) AS table_schema, CAST(NULL AS STRING) AS table_name, CAST(NULL AS STRING) AS column_name, CAST(NULL AS STRING) AS constraint_catalog, CAST(NULL AS STRING) AS constraint_schema, CAST(NULL AS STRING) AS constraint_name
  LIMIT 0
{%- else %}
{% for dataset in dataset_list -%}
  SELECT
  table_catalog,
table_schema,
table_name,
column_name,
constraint_catalog,
constraint_schema,
constraint_name
  FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`CONSTRAINT_COLUMN_USAGE`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
{%- endif -%}
)

SELECT
table_catalog,
table_schema,
table_name,
column_name,
constraint_catalog,
constraint_schema,
constraint_name
FROM
base
