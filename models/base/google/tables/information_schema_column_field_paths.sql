
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-column-field-paths -#}
    {# Required role/permissions: To query the INFORMATION_SCHEMA.COLUMN_FIELD_PATHS view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.admin
roles/bigquery.dataViewer
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT table_catalog, table_schema, table_name, column_name, field_path, data_type, description, collation_name, rounding_mode
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`COLUMN_FIELD_PATHS`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT table_catalog, table_schema, table_name, column_name, field_path, data_type, description, collation_name, rounding_mode
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`COLUMN_FIELD_PATHS`
    
    {%- endif %}
    )
    SELECT
    table_catalog, table_schema, table_name, column_name, field_path, data_type, description, collation_name, rounding_mode,
    FROM
    base
    