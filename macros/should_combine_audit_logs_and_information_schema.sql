{% macro should_combine_audit_logs_and_information_schema() -%}
{% if var('should_combine_audit_logs_and_information_schema') | lower == 'true' -%}
  {{ return(true) }}
{%- else -%}
  {{ return(false) }}
{%- endif %}
{%- endmacro %}
