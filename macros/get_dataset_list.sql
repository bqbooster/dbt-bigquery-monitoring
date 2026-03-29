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
    {% set raw_input_datasets = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_input_datasets() %}

    {% if raw_input_datasets is string and raw_input_datasets | length > 0 %}
      {% set dataset_parts = raw_input_datasets.split('.') %}
      {{ return([
        '`' ~ dataset_parts[0] ~ '`.`' ~ dataset_parts[1] ~ '`'
      ]) }}
    {% endif %}

    {% set preflight_sql %}
    SELECT CONCAT('`', CATALOG_NAME, '`.`', SCHEMA_NAME, '`') AS SCHEMA_NAME
    FROM `region-{{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
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
