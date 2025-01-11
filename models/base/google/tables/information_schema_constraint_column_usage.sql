
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-constraint-column-usage -#}
    
    
    {% set preflight_sql -%}
    SELECT
    CONCAT('`', CATALOG_NAME, '`.`', SCHEMA_NAME, '`') AS SCHEMA_NAME
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
    {%- endset %}
    {% set results = run_query(preflight_sql) %}
    {% set dataset_list = results | map(attribute='SCHEMA_NAME') | list %}
    {%- if dataset_list | length == 0 -%}
    {{ log("No datasets found in the project list", info=False) }}
    {%- endif -%}
    
    WITH base AS (
    {%- if dataset_list | length == 0 -%}
      SELECT CAST(NULL AS STRING) AS table_catalog, CAST(NULL AS STRING) AS table_schema, CAST(NULL AS STRING) AS table_name, CAST(NULL AS STRING) AS column_name, CAST(NULL AS STRING) AS constraint_catalog, CAST(NULL AS STRING) AS constraint_schema, CAST(NULL AS STRING) AS constraint_name
      LIMIT 0
    {%- else %}
    {% for dataset in dataset_list -%}
      SELECT table_catalog, table_schema, table_name, column_name, constraint_catalog, constraint_schema, constraint_name
      FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`PARTITIONS`
    {% if not loop.last %}UNION ALL{% endif %}
    {% endfor %}
    {%- endif -%}
    )
    SELECT
    table_catalog, table_schema, table_name, column_name, constraint_catalog, constraint_schema, constraint_name,
    FROM
    base
    