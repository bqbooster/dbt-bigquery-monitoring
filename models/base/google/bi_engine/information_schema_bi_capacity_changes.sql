{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-bi-capacity-changes -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT change_timestamp, project_id, project_number, bi_capacity_name, size, user_email, preferred_tables
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`BI_CAPACITY_CHANGES`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT
change_timestamp,
project_id,
project_number,
bi_capacity_name,
size,
user_email,
preferred_tables
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`BI_CAPACITY_CHANGES`
      {%- endif %}
      )

SELECT
      change_timestamp,
project_id,
project_number,
bi_capacity_name,
size,
user_email,
preferred_tables,
      FROM
      base
