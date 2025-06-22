{#- check if we pass explicitly projects (project mode) to materialize as a view using project references.
    It avoids following BQ error:
    Within a standard SQL view, references to tables/views require explicit project IDs
    unless the entity is created in the same project that is issuing the query,
    but these references are not project-qualified: "region-XXX.INFORMATION_SCHEMA.XXX"
 -#}
{% macro materialized_as_view_if_explicit_projects() -%}
  {% if project_list() | length > 0 %}
    {{ return('project_by_project_view') }}
  {% else %}
    {{ return('view') }}
  {% endif %}
{%- endmacro %}
