{% macro enable_gcp_bigquery_audit_logs() -%}
{% if var('enable_gcp_bigquery_audit_logs') == 'True' -%}
  {{ return(true) }}
{%- else -%}
  {{ return(false) }}
{%- endif %}
{%- endmacro %}
