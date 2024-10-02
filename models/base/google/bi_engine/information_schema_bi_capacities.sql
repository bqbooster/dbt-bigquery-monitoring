{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-bi-capacities -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT project_id, project_number, bi_capacity_name, size, preferred_tables
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`BI_CAPACITIES`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT
project_id,
project_number,
bi_capacity_name,
size,
preferred_tables
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`BI_CAPACITIES`
      {%- endif %}
      )

SELECT
      project_id,
project_number,
bi_capacity_name,
size,
preferred_tables,
      FROM
      base
