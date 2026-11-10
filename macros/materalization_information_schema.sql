{% macro dbt_bigquery_monitoring_materialization() %}
{% set projects = dbt_bigquery_monitoring.project_list() %}
  {#- If the user has set the materialization in the config that's different from the default -#}
  {% if dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_google_information_schema_model_materialization() != 'placeholder' %}
    {% set materialization = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_google_information_schema_model_materialization() %}
  {% elif projects|length == 0 %}
    {% set materialization = 'ephemeral' %}
  {% else %}
    {% set materialization = 'project_by_project_table' %}
  {% endif %}
  {{ return(materialization) }}
{% endmacro %}

{# Project configuration views were plain views before they opted into the
   package materialization. Region mode keeps that view. Project mode still
   materializes one table per input project. An explicit materialization var
   wins in both modes. Organization configuration views are not project-scoped
   and stay plain views in the model files. #}
{% macro dbt_bigquery_monitoring_configuration_materialization() %}
  {% set requested = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_google_information_schema_model_materialization() %}
  {% if requested == 'placeholder' and dbt_bigquery_monitoring.project_list() | length == 0 %}
    {{ return('view') }}
  {% else %}
    {{ return(dbt_bigquery_monitoring.dbt_bigquery_monitoring_materialization()) }}
  {% endif %}
{% endmacro %}
