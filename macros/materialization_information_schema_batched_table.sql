{%- materialization information_schema_batched_table, adapter='bigquery' -%}

{# Load INFORMATION_SCHEMA.PARTITIONS as separate BigQuery jobs so a dataset
   with more than 1000 tables stays under Google's scan limit. #}

  {%- set grant_config = config.get('grants') -%}
  {# Fusion rejects untyped relations in adapter.drop_relation() with
     "relation has no type" (InvalidConfig dbt1005). Core is more lenient,
     but both accept incorporate(type=...). #}
  {% set target_relation = this.incorporate(type='table') %}
  {% set existing_relation = load_relation(this) %}
  {% set empty_run = flags.EMPTY | default(false) %}

{{ run_hooks(pre_hooks) }}

{% if existing_relation is not none %}
  {% do adapter.drop_relation(existing_relation.incorporate(type='table')) %}
{% endif %}

{% set main_sql = [] %}
{% set build_sql = create_table_as(False, target_relation, dbt_bigquery_monitoring.information_schema_partitions_empty_sql()) %}
{# create_table_as() already ends with ';'. Appending it to main_sql and
   joining with ';\n' emits an empty statement ("Unexpected ';'") as soon as
   a later INSERT is added, which is every run that finds a dataset.
   Execute the create on its own, and only batch the inserts below. #}
{% do run_query(build_sql) %}

{% if not empty_run %}
  {% set partition_jobs = dbt_bigquery_monitoring.information_schema_partitions_job_sqls() %}
  {% for job_sql in partition_jobs %}
    {% set insert_sql %}
INSERT INTO {{ target_relation }} (
  table_catalog,
  table_schema,
  table_name,
  partition_id,
  total_rows,
  total_logical_bytes,
  total_billable_bytes,
  last_modified_time,
  storage_tier
)
{{ job_sql }}
    {% endset %}
    {% do main_sql.append(insert_sql) %}
  {% endfor %}
{% endif %}

{# statement('main') must be a real query. --empty and datasets with no
   tables produce no INSERTs. #}
{% if main_sql | length == 0 %}
  {% do main_sql.append('SELECT 1') %}
{% endif %}

{% call statement('main') -%}
  {{ main_sql | join(';\n') }}
{%- endcall %}

{{ run_hooks(post_hooks) }}
{% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
{% do apply_grants(target_relation, grant_config, should_revoke) %}
{% do persist_docs(target_relation, model) %}

{{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}
