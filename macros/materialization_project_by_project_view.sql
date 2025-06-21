{%- materialization project_by_project_view, adapter='bigquery' -%}

-- grab current tables grants config for comparision later on
{% set grant_config = config.get('grants') %}
{% set projects = project_list() %}

-- Build the SQL by unioning all projects
{% set union_sqls = [] %}
{% for project in projects %}
  {% set project_sql = sql | replace('`region-', '`' ~ project | trim ~ '`.`region-') %}
  {% do union_sqls.append('(' ~ project_sql ~ ')') %}
{% endfor %}

{% set final_sql = union_sqls | join('\nUNION ALL\n') %}

{% call statement('main') -%}
  {{ create_view_as(target_relation, final_sql) }}
{%- endcall %}

{% set target_relation = this.incorporate(type='view') %}

{% do persist_docs(target_relation, model) %}

{% if config.get('grant_access_to') %}
  {% for grant_target_dict in config.get('grant_access_to') %}
    {% do adapter.grant_access_to(this, 'view', None, grant_target_dict) %}
  {% endfor %}
{% endif %}

{{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}
