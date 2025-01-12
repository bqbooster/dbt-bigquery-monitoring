{% macro dbt_bigquery_monitoring_materialization() %}
{% set projects = project_list() %}
  {#- If the user has set the materialization in the config that's different from the default -#}
  {% if var('google_information_schema_model_materialization') != 'placeholder' %}
    {% set materialization = var('google_information_schema_model_materialization') %}
  {% elif projects|length == 0 %}
    {% set materialization = 'ephemeral' %}
  {% else %}
    {% set materialization = 'project_by_project_table' %}
  {% endif %}
  {{ return(materialization) }}
{% endmacro %}
