{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata -#}
{% for project in project_list() -%}
SELECT
catalog_name,
schema_name,
option_name,
option_type,
option_value,
FROM
  `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
