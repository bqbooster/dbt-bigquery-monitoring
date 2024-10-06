{% macro enable_gcp_billing_export() -%}
{% if var('enable_gcp_billing_export') -%}
  {{ return(true) }}
{%- else -%}
  {{ return(false) }}
{%- endif %}
{%- endmacro %}
