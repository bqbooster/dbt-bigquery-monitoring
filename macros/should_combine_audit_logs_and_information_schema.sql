{% macro should_combine_audit_logs_and_information_schema() -%}
  {{ return(dbt_bigquery_monitoring_variable_should_combine_audit_logs_and_information_schema()) }}
{%- endmacro %}
