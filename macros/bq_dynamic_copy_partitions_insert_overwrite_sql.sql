{#
  Override dbt-bigquery copy_partitions cleanup to avoid dropping the temp table twice.

  When on_schema_change is not "ignore", the incremental materialization creates the
  __dbt_tmp table first (tmp_relation_exists=true), then runs this macro. The adapter
  macro also drops the temp table in SQL while the materialization calls
  adapter.drop_relation() afterward, which can hang after partition copies complete.
#}
{% macro bq_dynamic_copy_partitions_insert_overwrite_sql(
  tmp_relation,
  target_relation,
  sql,
  unique_key,
  partition_by,
  dest_columns,
  tmp_relation_exists,
  copy_partitions
) %}
  {%- if tmp_relation_exists is false -%}
    {%- call statement('create_tmp_relation_for_copy', language='sql') -%}
      {{ bq_create_table_as(partition_by, true, tmp_relation, sql, 'sql') }}
    {%- endcall -%}
  {%- endif -%}

  {%- set partitions_sql -%}
    SELECT DISTINCT {{ partition_by.render_wrapped() }}
    FROM {{ tmp_relation }}
  {%- endset -%}

  {%- set partitions = run_query(partitions_sql).columns[0].values() -%}

  {%- do bq_copy_partitions(tmp_relation, target_relation, partitions, partition_by) -%}

  {%- if tmp_relation_exists is false -%}
    DROP TABLE IF EXISTS {{ tmp_relation }}
  {%- endif -%}
{% endmacro %}
