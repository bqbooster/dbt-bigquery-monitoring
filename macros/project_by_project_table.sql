{% macro project_by_project_table() %}
  {%- materialization 'project_by_project_table', adapter='bigquery' -%}

  {% set target_relation = this %}
  {% set existing_relation = load_relation(this) %}
  {% set tmp_relation = make_temp_relation(this) %}
  {% set projects = project_list() %}
  {% set partition_by = config.get('partition_by') %}

  {{ run_hooks(pre_hooks) }}

  -- Create the table if it doesn't exist
  {% if existing_relation is none %}
    {% set build_sql = create_table_as(False, target_relation, sql) %}
    {% do run_query(build_sql) %}
  {% else %}
    {% if partition_by is not none %}
      -- Get the maximum partition value
      {% set max_partition_sql %}
        SELECT MAX({{ partition_by }}) as max_partition
        FROM {{ target_relation }}
      {% endset %}
      {% set max_partition_result = run_query(max_partition_sql) %}
      {% set max_partition_value = max_partition_result['data'][0]['max_partition'] %}
    {% else %}
      -- Truncate the table if partition_by is not defined
      {% set truncate_sql %}
        TRUNCATE TABLE {{ target_relation }}
      {% endset %}
      {% do run_query(truncate_sql) %}
    {% endif %}
  {% endif %}

  -- If we have projects, process them one by one
  {% if projects|length > 0 %}
    {% for project in projects %}
      {% set project_sql = sql | replace('`region-', '`' ~ project | trim ~ '`.`region-') %}
      {% if existing_relation is not none and partition_by is not none %}
        {% set project_sql = project_sql + ' WHERE ' ~ partition_by ~ ' >= "' ~ max_partition_value ~ '"' %}
      {% endif %}
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
