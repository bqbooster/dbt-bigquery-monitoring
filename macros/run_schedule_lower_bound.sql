{#- compute the lower bound based on the run schedule for incremental workload -#}
{% macro run_schedule_lower_bound() -%}
{#- run time on previous hour, eg running at 2023-08-01 03:43:02 => 2023-08-01 02:00:00 -#}
{% if var('run_schedule') == 'hourly' %}
    TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR), HOUR)
{#- run time on previous day, eg running at 2023-08-01 03:43:02 => 2023-07-31 00:00:00 -#}
{% elif var('run_schedule') == 'daily' %}
    TIMESTAMP_TRUNC(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY), DAY)
{% endif %}
{%- endmacro %}
