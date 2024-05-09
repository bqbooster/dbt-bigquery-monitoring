{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata-links -#}
WITH base AS (
{% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT * FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_LINKS`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT * FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_LINKS`
{%- endif %}
)
SELECT
catalog_name,
schema_name,
linked_schema_catalog_number,
linked_schema_catalog_name,
linked_schema_name,
linked_schema_creation_time,
linked_schema_org_display_name,
FROM
  base
