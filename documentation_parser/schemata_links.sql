{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata -#}
{% for project in project_list() -%}
SELECT
catalog_name,
schema_name,
linked_schema_catalog_number,
linked_schema_catalog_name,
linked_schema_name,
linked_schema_creation_time,
linked_schema_org_display_name,
FROM
  `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
