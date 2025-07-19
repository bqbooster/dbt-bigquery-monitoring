{#-- retrieve the projects list --#}
{% macro project_list() %}
  {% set projects = dbt_bigquery_monitoring_variable_input_gcp_projects() %}

  {#-- If it's already a list/array, return it directly --#}
  {% if projects is iterable and projects is not string %}
    {{ log("1 - projects: " ~ projects, info=True) }}
    {{ return(projects) }}

  {#-- Handle string inputs --#}
  {% elif projects is string %}
    {#-- Empty string case --#}
    {% if projects == '' %}
      {{ log("2 - projects: " ~ projects, info=True) }}
      {{ return([]) }}
    {% endif %}

    {#-- Check if it looks like a JSON array (starts with [ and ends with ]) --#}
    {% if projects.startswith('[') and projects.endswith(']') %}
      {% set projects_replaced = projects | replace("'", '"') %}

      {#-- Handle unquoted array values like [test1,test2] by adding quotes around values --#}
      {% if '","' not in projects_replaced and '"' not in projects_replaced %}
        {#-- Remove brackets, split by comma, add quotes, and rebuild --#}
        {% set inner_content = projects[1:-1] %}
        {% if ',' in inner_content %}
          {% set project_names = inner_content.split(',') %}
          {% set quoted_projects = [] %}
          {% for project_name in project_names %}
            {% set trimmed_project = project_name.strip() %}
            {% if trimmed_project %}
              {% set _ = quoted_projects.append('"' ~ trimmed_project ~ '"') %}
            {% endif %}
          {% endfor %}
          {% set projects_replaced = '[' ~ quoted_projects | join(',') ~ ']' %}
        {% else %}
          {#-- Single project in brackets like [test] --#}
          {% set trimmed_project = inner_content.strip() %}
          {% set projects_replaced = '["' ~ trimmed_project ~ '"]' %}
        {% endif %}
      {% endif %}

      {% set json = fromjson('{"v":' ~ projects_replaced ~ '}') %}
      {% if json and json.v %}
        {{ log("3 - json.v: " ~ json.v, info=True) }}
        {{ return(json.v) }}
      {% else %}
        {#-- Failed to parse JSON, treat as single project --#}
        {{ log("4 projects: " ~ projects, info=True) }}
        {{ return([projects]) }}
      {% endif %}
    {% else %}
      {#-- Single project string - wrap in array --#}
      {{ log("5 projects: " ~ projects, info=True) }}
      {{ return([projects]) }}
    {% endif %}

  {#-- Fallback: return empty array for any other type --#}
  {% else %}
    {{ log("6 projects: " ~ projects, info=True) }}
    {{ return([]) }}
  {% endif %}
{% endmacro %}
