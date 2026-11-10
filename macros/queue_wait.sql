{#- Queue wait is creation to start. Execution time is start to end (total_time_seconds). -#}
{% macro queue_wait_ms(creation_time='creation_time', start_time='start_time') -%}
TIMESTAMP_DIFF({{ start_time }}, {{ creation_time }}, MILLISECOND)
{%- endmacro %}
