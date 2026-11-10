{% macro drop_ci_partitions_table() %}
  {# The non-empty partitions check materializes a table. Later CI steps
     build the same model as a view, which BigQuery rejects while a table
     of that name exists. #}
  {% set relation = adapter.get_relation(
    database=target.project,
    schema=target.schema,
    identifier='information_schema_partitions'
  ) %}
  {% if relation is not none %}
    {% do adapter.drop_relation(relation) %}
  {% endif %}
{% endmacro %}
