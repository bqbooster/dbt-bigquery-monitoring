
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-constraint-column-usage -#}
    
    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT table_catalog, table_schema, table_name, column_name, constraint_catalog, constraint_schema, constraint_name
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`CONSTRAINT_COLUMN_USAGE`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT table_catalog, table_schema, table_name, column_name, constraint_catalog, constraint_schema, constraint_name
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`CONSTRAINT_COLUMN_USAGE`
    
    {%- endif %}
    )
    SELECT
    table_catalog, table_schema, table_name, column_name, constraint_catalog, constraint_schema, constraint_name,
    FROM
    base
    