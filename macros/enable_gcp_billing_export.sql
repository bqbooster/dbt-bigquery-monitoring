{% macro enable_gcp_billing_export() -%}
{% if var('enable_gcp_billing_export') == 'True' -%}
  {{ return(true) }}
{%- else -%}
  {{ return(false) }}
{%- endif %}
{%- endmacro %}
