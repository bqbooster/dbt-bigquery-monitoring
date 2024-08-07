
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-key-column-usage -#}
    
    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT constraint_catalog, constraint_schema, constraint_name, table_catalog, table_schema, table_name, column_name, ordinal_position, position_in_unique_constraint
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`KEY_COLUMN_USAGE`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT constraint_catalog, constraint_schema, constraint_name, table_catalog, table_schema, table_name, column_name, ordinal_position, position_in_unique_constraint
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`KEY_COLUMN_USAGE`
    
    {%- endif %}
    )
    SELECT
    constraint_catalog, constraint_schema, constraint_name, table_catalog, table_schema, table_name, column_name, ordinal_position, position_in_unique_constraint,
    FROM
    base
    