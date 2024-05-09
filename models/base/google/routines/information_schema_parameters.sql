{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-parameters -#}
{# Required role/permissions: To query the INFORMATION_SCHEMA.PARAMETERS view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.routines.get
bigquery.routines.list
Each of the following predefined IAM roles includes the
permissions that you need to get routine metadata:
roles/bigquery.admin
roles/bigquery.metadataViewer
roles/bigquery.dataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}
WITH base AS (
{% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT * FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`PARAMETERS`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT * FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`PARAMETERS`
{%- endif %}
)
SELECT
specific_catalog,
specific_schema,
specific_name,
ordinal_position,
parameter_mode,
is_result,
parameter_name,
data_type,
parameter_default,
is_aggregate,
FROM
  base
