{%- materialization project_by_project_table, adapter='bigquery' -%}

{% set target_relation = this %}
{% set existing_relation = load_relation(this) %}
{% set projects = project_list() %}
{%- set raw_partition_by = config.get('partition_by', none) -%}
{%- set partition_config = adapter.parse_partition_by(raw_partition_by) -%}
{%- set full_refresh_mode = (should_full_refresh()) -%}

{{ run_hooks(pre_hooks) }}

-- Create the table if it doesn't exist or if we're in full-refresh mode
{% if existing_relation is none or full_refresh_mode %}
  {% call statement('main') -%}
    {% if partition_config is not none %}
      {% set build_sql = create_table_as(False, target_relation, sql) %}
      -- Add partition expiration to the table to 180 days like information_schema tables
      {% set partition_expiration_sql %}
        ALTER TABLE {{ target_relation }}
        SET OPTIONS (
          expiration_timestamp = 180
        )
      {% endset %}
      {{ partition_expiration_sql }}
      {% do run_query(partition_expiration_sql) %}
    {% else %}
      {% set build_sql = create_table_as(False, target_relation, sql) %}
    {% endif %}
    {{ build_sql }}
  {%- endcall %}
{% else %}
  {% call statement('main') -%}
      SELECT 1
  {%- endcall %}
    {% if partition_config is not none %}
      -- Get the maximum partition value
      {% set max_partition_sql %}
        SELECT MAX({{ partition_config.field }}) as max_partition
        FROM {{ target_relation }}
      {% endset %}
    {% else %}
      -- Truncate the table if partition_by is not defined
      {% set truncate_sql %}
        TRUNCATE TABLE {{ target_relation }}
      {% endset %}
      {{ truncate_sql }}
      {% do run_query(truncate_sql) %}
    {% endif %}
  {% if partition_config is not none %}
    {% set max_partition_result = run_query(max_partition_sql) %}
    {% if max_partition_result['data']|length > 0 %}
      {% set max_partition_value = max_partition_result['data'][0]['max_partition'] %}
    {% else %}
      {% set max_partition_value = none %}
    {% endif %}
  {% endif %}
{% endif %}

-- If we have projects, process them one by one
{% if projects|length > 0 %}
  {% set all_insert_sql = [] %}
  {% for project in projects %}
    {% set project_sql = sql | replace('`region-', '`' ~ project | trim ~ '`.`region-') %}
    {% if existing_relation is not none and partition_config is not none and max_partition_value is not none %}
      {% set project_sql = project_sql + ' WHERE ' ~ partition_config.field ~ ' >= "' ~ max_partition_value ~ '"' %}
    {% endif %}
    {% set insert_sql %}
      INSERT INTO {{ target_relation }}
      {{ project_sql }}
    {% endset %}
    {% do all_insert_sql.append(insert_sql) %}
  {% endfor %}
  {% call statement('insert') -%}
    {{ all_insert_sql | join(';\n') }}
  {%- endcall %}
{% endif %}

{{ run_hooks(post_hooks) }}
{% set should_revoke = should_revoke(old_relation, full_refresh_mode=True) %}
{% do apply_grants(target_relation, grant_config, should_revoke) %}
{% do persist_docs(target_relation, model) %}

{{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}
