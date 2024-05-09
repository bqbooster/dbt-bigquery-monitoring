{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata-options -#}
WITH base AS (
{% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT * FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_OPTIONS`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT * FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_OPTIONS`
{%- endif %}
)
SELECT
catalog_name,
schema_name,
option_name,
option_type,
option_value,
FROM
  base
