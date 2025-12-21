{# 
  Get a cached list of datasets for INFORMATION_SCHEMA queries.
  
  This macro fetches datasets from INFORMATION_SCHEMA.SCHEMATA and caches the result
  to avoid redundant queries when multiple models need the same data.
  
  Usage:
    {% set dataset_list = get_dataset_list() %}
    
  Returns:
    A list of fully-qualified dataset names like ['`project`.`dataset`', ...]
#}
{% macro get_dataset_list() %}
  {# Only execute during actual run, not during parsing #}
  {% if execute %}
    {% set preflight_sql %}
    SELECT CONCAT('`', CATALOG_NAME, '`.`', SCHEMA_NAME, '`') AS SCHEMA_NAME
    FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
    {% endset %}
    
    {% set results = run_query(preflight_sql) %}
    {% set dataset_list = results | map(attribute='SCHEMA_NAME') | list %}
    
    {%- if dataset_list | length == 0 -%}
      {{ log("[dbt-bigquery-monitoring] No datasets found in the project list", info=False) }}
    {%- endif -%}
    
    {{ return(dataset_list) }}
  {% else %}
    {{ return([]) }}
  {% endif %}
{% endmacro %}
