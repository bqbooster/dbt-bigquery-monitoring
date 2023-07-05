{#- macro replace the suffix from sharded table to merge as a single table for cost monitoring -#}
{% macro sharded_table_merger(table_name_field) -%}
REGEXP_REPLACE(
  REGEXP_REPLACE(
    {{ table_name_field }},
    r"(\d{8,10})$", "<date>"),
  r"(20\d\dQ[1-4])$", "<quarter>")
{%- endmacro %}
