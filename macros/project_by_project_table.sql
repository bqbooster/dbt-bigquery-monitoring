{%- materialization project_by_project_table, adapter='bigquery' -%}

-- If we have projects, process them one by one
-- This materialization should only be used in project mode if it isn't the case please report a bug

-- grab current tables grants config for comparision later on
  {%- set grant_config = config.get('grants') -%}

  {% set existing_relation = load_relation(this) %}
  {% set projects = project_list() %}
  {%- set raw_partition_by = config.get('partition_by', none) -%}
  {%- set partition_config = adapter.parse_partition_by(raw_partition_by) -%}
  {%- set cluster_by = config.get('cluster_by', none) -%}
  {%- set full_refresh_mode = (should_full_refresh()) -%}

{{ run_hooks(pre_hooks) }}

{%- set sql_no_data = sql + " LIMIT 0" %}

-- Create the table if it doesn't exist or if we're in full-refresh mode
{% if existing_relation is none or full_refresh_mode %}
  {#-- If the partition/cluster config has changed, then we must drop and recreate --#}
  {% if not adapter.is_replaceable(existing_relation, partition_config, cluster_by) %}
      {% do log("Hard refreshing " ~ existing_relation ~ " because it is not replaceable") %}
      {{ adapter.drop_relation(existing_relation) }}
  {% endif %}
  {% set build_sql = create_table_as(False, target_relation, sql_no_data) %}
  {{ build_sql }}
  {% do run_query(build_sql) %}
{% else %}
  {% if partition_config is not none %}
    -- Get the maximum partition value
    {% set max_partition_sql %}
      SELECT FORMAT_TIMESTAMP("%F %T", MAX({{ partition_config.field }})) as max_partition
      FROM {{ target_relation }}
      WHERE {{ partition_config.field }} IS NOT NULL
    {% endset %}
    -- find maximum partition value to insert only new data
    {% set max_partition_result = run_query(max_partition_sql) %}
    {% if max_partition_result|length > 0 %}
      {% set max_partition_value = max_partition_result.columns[0].values()[0] %}
    {% endif %}
  {% else %} -- if  table exists
    -- Truncate the table if partition_by is not defined
    {% set truncate_sql %}
      TRUNCATE TABLE {{ target_relation }}
    {% endset %}
    {{ truncate_sql }}
    {% do run_query(truncate_sql) %}
  {% endif %}

  -- Check if the schema has changed
{% endif %}

{% set main_sql = [] %}

{#- Incremental case -#}
  {% if existing_relation is not none %}
    {#- with partitioned data special where condition #}
    {% if partition_config is not none and max_partition_value is not none and max_partition_value | length > 0 %}
      {% set where_condition = 'WHERE ' ~ partition_config.field ~ ' >= TIMESTAMP_TRUNC("' ~ max_partition_value ~ '", HOUR)' %}
    {% else %}
      {% set where_condition = 'WHERE TRUE' %}
    {% endif %}

    {#- Delete from statement when incremental case -#}
    {#- That statement is common to all projects -#}
    {% set delete_sql %}
          DELETE FROM {{ target_relation }}
          {{ where_condition }}
    {% endset %}
    {% do main_sql.append(delete_sql) %}
{% endif %}

{% for project in projects %}
  {% set project_sql = sql | replace('`region-', '`' ~ project | trim ~ '`.`region-') %}
  {#- Incremental case -#}
  {% if existing_relation is not none %}

    {#- with regular data where condition #}
    {% set insert_sql %}
      INSERT INTO {{ target_relation }}
      {{ project_sql }}
      {{ where_condition }}
    {% endset %}

  {% else %}

    {#- "Full-refresh" case -#}
    {% if partition_config is not none %}

      {#- bigquery doesn't allow more than 4000 partitions per insert so if we have hourly tables it's ~ 166 days -#}
      {% set project_sql = project_sql + ' WHERE ' ~ partition_config.field ~ ' >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 166 DAY)' %}
    {% endif %}

    {% set insert_sql %}
      INSERT INTO {{ target_relation }}
      {{ project_sql }}
    {% endset %}

  {% endif %}
  {% do main_sql.append(insert_sql) %}
{% endfor %}

{% call statement('main') -%}
  {{ main_sql | join(';\n') }}
{%- endcall %}


{{ run_hooks(post_hooks) }}
{% set should_revoke = should_revoke(old_relation, full_refresh_mode=True) %}
{% do apply_grants(target_relation, grant_config, should_revoke) %}
{% do persist_docs(target_relation, model) %}

{{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}
