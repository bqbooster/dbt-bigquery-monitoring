{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-index-columns -#}
{# Required role/permissions: To see search index metadata, you need the
bigquery.tables.get or bigquery.tables.list Identity and Access Management (IAM)
permission on the table with the index. Each of the following predefined
IAM roles includes at least one of these permissions:
roles/bigquery.admin
roles/bigquery.dataEditor
roles/bigquery.dataOwner
roles/bigquery.dataViewer
roles/bigquery.metadataViewer
roles/bigquery.user
For more information about BigQuery permissions, see
Access control with IAM. -#}

WITH base AS (
  {% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT index_catalog, index_schema, table_name, index_name, index_column_name, index_field_path
  FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SEARCH_INDEX_COLUMNS`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT
index_catalog,
index_schema,
table_name,
index_name,
index_column_name,
index_field_path
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SEARCH_INDEX_COLUMNS`
{%- endif %}
)

SELECT
index_catalog,
index_schema,
table_name,
index_name,
index_column_name,
index_field_path,
FROM
base
