
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT catalog_name, schema_name, schema_owner, creation_time, last_modified_time, location, ddl, default_collation_name
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT catalog_name, schema_name, schema_owner, creation_time, last_modified_time, location, ddl, default_collation_name
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
      {%- endif %}
      )
      SELECT
      catalog_name, schema_name, schema_owner, creation_time, last_modified_time, location, ddl, default_collation_name,
      FROM
      base
      