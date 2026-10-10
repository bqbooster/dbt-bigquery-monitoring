{% macro assert_audit_logs_sink_inspect_gated() %}
  {% set should_inspect = dbt_bigquery_monitoring.gcp_bigquery_audit_logs_should_inspect_sink() %}
  {% set which = flags.WHICH | default('') %}

  {% if should_inspect %}
    {% do exceptions.raise_compiler_error(
      "sink inspect must be false during run-operation (flags.WHICH=" ~ which ~ ")"
    ) %}
  {% endif %}
{% endmacro %}
