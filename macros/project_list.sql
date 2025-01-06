{#-- retrieve the projects list --#}
{% macro project_list() %}
  {% set projects = var('input_gcp_projects', []) %}
  {% if projects is iterable and projects is not string %}
     {{ return(projects) }}
  {#-- check if it's the string and it contains a "," --#}
  {% elif projects is string %}
     {% if projects == '' %}
       {{ return([]) }}
     {% else %}
       {% set projects_replaced = projects | replace("'", '"') %}
       {% set json = fromjson('{"v":' ~ projects_replaced ~ '}') %}
       {{ return (json['v']) }}
     {% endif %}
  {% else %}
    {{ exceptions.raise_compiler_error('Invalid `input_gcp_projects` variables. Got: ' ~ input_gcp_projects ~ ' but expected form like input_gcp_projects = ["project_1", "project_2"] ') }}
  {% endif %}
{% endmacro %}
