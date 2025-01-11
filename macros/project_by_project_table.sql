{%- materialization project_by_project_table, adapter='bigquery' -%}

{% set target_relation = this %}
{% set existing_relation = load_relation(this) %}
{% set tmp_relation = make_temp_relation(this) %}
{% set projects = project_list() %}
{%- set raw_partition_by = config.get('partition_by', none) -%}
{%- set partition_config = adapter.parse_partition_by(raw_partition_by) -%}
{{ log("project_by_project_table with partition_by : " ~ partition_by, info=True) }}

{{ run_hooks(pre_hooks) }}

-- Create the table if it doesn't exist
{% if existing_relation is none %}
  {% call statement('main') -%}
    {% if partition_config is not none %}
      {{ log("Creating table with partition_by : " ~ partition_by, info=True) }}
      {% set build_sql = create_table_as(False, target_relation, sql) %}
    {% else %}
      {{ log("Creating table without partition_by", info=True) }}
      {% set build_sql = create_table_as(False, target_relation, sql) %}
    {% endif %}
    {{ log("Running build_sql : " ~ build_sql, info=True) }}
    {{ build_sql }}
  {%- endcall %}
{% else %}
  {% call statement('main') -%}
      SELECT 1
  {%- endcall %}
    {{ log("Table already exists", info=True) }}
    {% if partition_config is not none %}
      -- Get the maximum partition value
      {% set max_partition_sql %}
        SELECT MAX({{ partition_config.field }}) as max_partition
        FROM {{ target_relation }}
      {% endset %}
      {{ log("Running max_partition_sql : " ~ max_partition_sql, info=True) }}
    {% else %}
      -- Truncate the table if partition_by is not defined
      {% set truncate_sql %}
        TRUNCATE TABLE {{ target_relation }}
      {% endset %}
      {{ log("Running truncate_sql : " ~ truncate_sql, info=True) }}
      {{ truncate_sql }}
      {% do run_query(truncate_sql) %}
    {% endif %}
  {{ log("Check partition_config", info=True) }}
  {% if partition_config is not none %}
    {{ log("Getting max_partition_value", info=True) }}
    {% set max_partition_result = run_query(max_partition_sql) %}
    {{ log("max_partition_result : " ~ max_partition_result, info=True) }}
    {% if max_partition_result['data']|length > 0 %}
      {% set max_partition_value = max_partition_result['data'][0]['max_partition'] %}
      {{ log("max_partition_value : " ~ max_partition_value, info=True) }}
    {% else %}
      {% set max_partition_value = none %}
      {{ log("No max_partition_value found", info=True) }}
    {% endif %}
  {% endif %}
{% endif %}

-- If we have projects, process them one by one
{% if projects|length > 0 %}
  {% set all_insert_sql = [] %}
  {% for project in projects %}
    {{ log("Processing project : " ~ project, info=True) }}
    {% set project_sql = sql | replace('`region-', '`' ~ project | trim ~ '`.`region-') %}
    {% if existing_relation is not none and partition_config is not none and max_partition_value is not none %}
      {% set project_sql = project_sql + ' WHERE ' ~ partition_config.field ~ ' >= "' ~ max_partition_value ~ '"' %}
    {% endif %}
    {% set insert_sql %}
      INSERT INTO {{ target_relation }}
      {{ project_sql }}
    {% endset %}
    {{ log("Running insert_sql : " ~ insert_sql, info=True) }}
    {% do all_insert_sql.append(insert_sql) %}
  {% endfor %}
  {{ log(" all_insert_sql : " ~ all_insert_sql, info=True) }}
  {% call statement('insert') -%}
    {{ all_insert_sql | join(';\n') }}
  {%- endcall %}
{% endif %}

{{ log("Materialization complete", info=True) }}
{{ run_hooks(post_hooks) }}

{{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}
