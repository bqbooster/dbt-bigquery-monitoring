{#-- macro to control the copy_partitions usage at project level for this package #}
{% macro should_use_copy_partitions() -%}
{% if var('use_copy_partitions') == 'True' -%}
  {{ return(true) }}
{%- else -%}
  {{ return(false) }}
{%- endif %}
{%- endmacro %}
