{% macro dbt_bigquery_monitoring_materialization() %}
  {% set projects = project_list() %}
  {% if projects|length == 0 %}
    {% set materialization = 'ephemeral' %}
  {% else %}
    {% set materialization = 'project_by_project_table' %}
  {% endif %}
  {{ return(materialization) }}
{% endmacro %}
