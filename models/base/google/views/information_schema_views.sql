
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-views -#}
    {# Required role/permissions: To get view metadata, you need the following Identity and Access Management (IAM)
permissions:
bigquery.tables.get
bigquery.tables.list
Each of the following predefined IAM roles includes the
permissions that you need in order to get view metadata:
roles/bigquery.admin
roles/bigquery.dataEditor
roles/bigquery.metadataViewer
roles/bigquery.dataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT table_catalog, table_schema, table_name, view_definition, check_option, use_standard_sql
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`VIEWS`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT table_catalog, table_schema, table_name, view_definition, check_option, use_standard_sql
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`VIEWS`
    
    {%- endif %}
    )
    SELECT
    table_catalog, table_schema, table_name, view_definition, check_option, use_standard_sql,
    FROM
    base
    