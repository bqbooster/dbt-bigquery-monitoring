{%- materialization project_by_project_table, adapter='bigquery' -%}

{% set target_relation = this %}
{% set existing_relation = load_relation(this) %}
{% set projects = project_list() %}
{%- set raw_partition_by = config.get('partition_by', none) -%}
{%- set partition_config = adapter.parse_partition_by(raw_partition_by) -%}
{%- set full_refresh_mode = (should_full_refresh()) -%}

{{ run_hooks(pre_hooks) }}

{%- set sql_no_data = sql + " LIMIT 0" %}

-- Create the table if it doesn't exist or if we're in full-refresh mode
{% if existing_relation is none or full_refresh_mode %}
  {% call statement('main') -%}
    {% if partition_config is not none %}
      {% set build_sql = create_table_as(False, target_relation, sql_no_data) %}
    {% else %}
      {% set build_sql = create_table_as(False, target_relation, sql_no_data) %}
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
        SELECT FORMAT_TIMESTAMP("%F %T", MAX({{ partition_config.field }})) as max_partition
        FROM {{ target_relation }}
        WHERE {{ partition_config.field }} IS NOT NULL
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
    {% if max_partition_result|length > 0 %}
      {% set max_partition_value = max_partition_result.columns[0].values()[0] %}
    {% endif %}
  {% endif %}
{% endif %}

-- If we have projects, process them one by one
{% if projects|length > 0 %}
  {% set all_insert_sql = [] %}
  {% for project in projects %}
    {% set project_sql = sql | replace('`region-', '`' ~ project | trim ~ '`.`region-') %}
    {% if existing_relation is not none and partition_config is not none and max_partition_value is not none and max_partition_value | length > 0 %}
      {% set where_condition = 'WHERE ' ~ partition_config.field ~ ' >= TIMESTAMP_TRUNC("' ~ max_partition_value ~ '", HOUR)' %}
      {% set insert_sql %}
        DELETE FROM {{ target_relation }}
        {{ where_condition }};

        INSERT INTO {{ target_relation }}
        {{ project_sql }}
        {{ where_condition }}
      {% endset %}
    {% else %}
       {#- bigquery doesn't allow more than 4000 partitions per insert so if we have hourly tables it's ~ 166 days -#}
      {% set project_sql = project_sql + ' WHERE ' ~ partition_config.field ~ ' >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 166 DAY)' %}
      {% set insert_sql %}
        INSERT INTO {{ target_relation }}
        {{ project_sql }}
      {% endset %}
    {% endif %}
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
