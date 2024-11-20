{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-storage-usage-by-organization -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.TABLE_STORAGE_USAGE_TIMELINE_BY_ORGANIZATION view, you
need the following Identity and Access Management (IAM) permissions for your organization:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
roles/bigquery.admin
This schema view is only available to users with defined Google Cloud
organizations.For more information about BigQuery permissions, see
Access control with IAM. -#}

WITH base AS (
  {% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT project_id, table_catalog, project_number, table_schema, table_name, billable_total_logical_usage, billable_active_logical_usage, billable_long_term_logical_usage, billable_total_physical_usage, billable_active_physical_usage, billable_long_term_physical_usage
  FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE_USAGE_TIMELINE_BY_ORGANIZATION`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT
project_id,
table_catalog,
project_number,
table_schema,
table_name,
billable_total_logical_usage,
billable_active_logical_usage,
billable_long_term_logical_usage,
billable_total_physical_usage,
billable_active_physical_usage,
billable_long_term_physical_usage
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE_USAGE_TIMELINE_BY_ORGANIZATION`
{%- endif %}
)

SELECT
project_id,
table_catalog,
project_number,
table_schema,
table_name,
billable_total_logical_usage,
billable_active_logical_usage,
billable_long_term_logical_usage,
billable_total_physical_usage,
billable_active_physical_usage,
billable_long_term_physical_usage,
FROM
base
