{#- macro to add cost related formula to base jobs table  -#}
{% macro sharded_table_merger(table_name) -%}
REGEXP_REPLACE(
REGEXP_REPLACE(
  bq_storage.table_name,
   r"(\d{8,10})$", "<date>"),
    r"(20\d\dQ[1-4])$", "<quarter>") AS bq_storage_table_name_pattern
{%- endmacro %}
