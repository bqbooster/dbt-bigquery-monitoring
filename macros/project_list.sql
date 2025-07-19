{#-- retrieve the projects list --#}
{% macro project_list() %}
  {% set projects = dbt_bigquery_monitoring_variable_input_gcp_projects() %}

  {#-- If it's already a list/array, return it directly --#}
  {% if projects is iterable and projects is not string %}
    {{ return(projects) }}

  {#-- Handle string inputs --#}
  {% elif projects is string %}
    {#-- Empty string case --#}
    {% if projects == '' %}
      {{ return([]) }}
    {% endif %}

    {#-- Check if it looks like an array (starts with [ and ends with ]) --#}
    {% if projects.startswith('[') and projects.endswith(']') %}
      {#-- Extract content between brackets --#}
      {% set inner_content = projects[1:-1].strip() %}

      {#-- Handle empty array --#}
      {% if inner_content == '' %}
        {{ return([]) }}
      {% endif %}

      {#-- Split by comma and process each project --#}
      {% set project_list = [] %}
      {% set raw_projects = inner_content.split(',') %}

      {% for raw_project in raw_projects %}
        {% set cleaned_project = raw_project.strip() %}

        {#-- Remove surrounding quotes if present --#}
        {% if (cleaned_project.startswith('"') and cleaned_project.endswith('"')) or
              (cleaned_project.startswith("'") and cleaned_project.endswith("'")) %}
          {% set cleaned_project = cleaned_project[1:-1] %}
        {% endif %}

        {#-- Add non-empty projects to the list --#}
        {% if cleaned_project %}
          {% set _ = project_list.append(cleaned_project) %}
        {% endif %}
      {% endfor %}

      {{ return(project_list) }}
    {% else %}
      {#-- Single project string - wrap in array --#}
      {{ return([projects]) }}
    {% endif %}

  {#-- Fallback: return empty array for any other type --#}
  {% else %}
    {{ return([]) }}
  {% endif %}
{% endmacro %}
