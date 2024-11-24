{#- check if var('projects') is defined to materialize as a view if empty else an ephemeral
    It avoids following BQ error:
    Within a standard SQL view, references to tables/views require explicit project IDs
    unless the entity is created in the same project that is issuing the query,
    but these references are not project-qualified: "region-XXX.INFORMATION_SCHEMA.XXX"
 -#}
{% macro materialized_as_view_if_explicit_projects() -%}
  {% if var('input_gcp_projects', []) | length == 0 %}
    {{ return('ephemeral') }}
  {% else %}
    {{ return('view') }}
  {% endif %}
{%- endmacro %}
