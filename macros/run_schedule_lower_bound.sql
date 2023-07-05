{#- compute the lower bound based on the run schedule for incremental workload -#}
{% macro run_schedule_lower_bound() -%}
{% if var('run_schedule') == 'hourly' %}
    TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR), HOUR)
{% elif var('run_schedule') == 'daily' %}
    TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY), DAY)
{% endif %}
{%- endmacro %}
