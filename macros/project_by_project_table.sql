{% macro project_by_project_table() %}
  {%- materialization 'project_by_project_table', adapter='bigquery' -%}

  {% set target_relation = this %}
  {% set existing_relation = load_relation(this) %}
  {% set tmp_relation = make_temp_relation(this) %}
  {% set projects = project_list() %}

  {{ run_hooks(pre_hooks) }}

  -- Create the table if it doesn't exist
  {% if existing_relation is none %}
    {% set build_sql = create_table_as(False, target_relation, sql) %}
    {% do run_query(build_sql) %}
  {% endif %}

  -- If we have projects, process them one by one
  {% if projects|length > 0 %}
    {% for project in projects %}
      {% set project_sql = sql | replace('`region-', '`' ~ project | trim ~ '`.`region-') %}
      {% set insert_sql %}
        INSERT INTO {{ target_relation }}
        {{ project_sql }}
      {% endset %}
      {% do run_query(insert_sql) %}
    {% endfor %}
  {% endif %}

  {{ run_hooks(post_hooks) }}

  {{ return({'relations': [target_relation]}) }}

  {%- endmaterialization -%}
{% endmacro %}
