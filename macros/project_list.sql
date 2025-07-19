{#--
  Retrieve the projects list from various input formats and always return an array.

  This macro supports multiple input formats and normalizes them to a consistent array output:

  SUPPORTED INPUT FORMATS:

  1. dbt project variables (dbt_project.yml):
     vars:
       input_gcp_projects: "single-project"                    # → ["single-project"]
       input_gcp_projects: ["project1", "project2"]            # → ["project1", "project2"]

  2. CLI variables:
     --vars '{"input_gcp_projects": "test"}'                   # → ["test"]
     --vars '{"input_gcp_projects": ["test1", "test2"]}'       # → ["test1", "test2"]

  3. Environment variables:
     DBT_BQ_MONITORING_GCP_PROJECTS="single-project"          # → ["single-project"]
     DBT_BQ_MONITORING_GCP_PROJECTS='["project1","project2"]' # → ["project1", "project2"]
     DBT_BQ_MONITORING_GCP_PROJECTS='[project1,project2]'     # → ["project1", "project2"] (unquoted)
     DBT_BQ_MONITORING_GCP_PROJECTS='["project1"]'            # → ["project1"]
     DBT_BQ_MONITORING_GCP_PROJECTS='[project1]'              # → ["project1"] (unquoted)
     DBT_BQ_MONITORING_GCP_PROJECTS='[]'                      # → []

  4. Mixed quote styles:
     DBT_BQ_MONITORING_GCP_PROJECTS="['proj1',\"proj2\"]"     # → ["proj1", "proj2"]

  EDGE CASES HANDLED:
  - Empty strings return empty arrays
  - Whitespace around project names is automatically trimmed
  - Surrounding quotes (single or double) are automatically removed
  - Invalid/malformed inputs fallback gracefully

  RETURN VALUE:
  Always returns an array of project strings
--#}
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
