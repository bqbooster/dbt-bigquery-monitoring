{#-
  USD per slot-hour for one edition and plan. Defaults follow the published
  US list on https://cloud.google.com/bigquery/pricing (November 2026):
  pay-as-you-go Standard 0.04, Enterprise 0.06, Enterprise Plus 0.10.
  Enterprise and Enterprise Plus commitment defaults are 1-year and 3-year
  resource commitments (20% and 40% off). Standard has no slot commitment;
  its commitment defaults are the 1-year and 3-year spend-based CUD rates.
  Override per region or contract. Unknown editions use hourly_slot_price.
-#}
{% macro dbt_bigquery_monitoring_edition_slot_price(edition, plan) %}
    {% set normalized_plan = plan | string | trim | lower %}
    {% set prices = {
        'standard': {
            'pay_as_you_go': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_standard_payg_slot_price(),
            'commitment_1_year': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_standard_commitment_1y_slot_price(),
            'commitment_3_year': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_standard_commitment_3y_slot_price(),
        },
        'enterprise': {
            'pay_as_you_go': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_enterprise_payg_slot_price(),
            'commitment_1_year': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_enterprise_commitment_1y_slot_price(),
            'commitment_3_year': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_enterprise_commitment_3y_slot_price(),
        },
        'enterprise_plus': {
            'pay_as_you_go': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_enterprise_plus_payg_slot_price(),
            'commitment_1_year': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_enterprise_plus_commitment_1y_slot_price(),
            'commitment_3_year': dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_enterprise_plus_commitment_3y_slot_price(),
        },
    } %}
    {% if normalized_plan not in prices['standard'] %}
        {% do exceptions.raise_compiler_error(
            "slot_pricing_plan must be pay_as_you_go, commitment_1_year, or commitment_3_year. Got: " ~ plan
        ) %}
    {% endif %}
    {% if edition not in prices %}
        {% do exceptions.raise_compiler_error("Unknown edition price key: " ~ edition) %}
    {% endif %}
    {{ return(prices[edition][normalized_plan]) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_edition_price_case(plan, edition_sql='edition') %}
CASE UPPER(CAST({{ edition_sql }} AS STRING))
    WHEN 'STANDARD' THEN {{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_edition_slot_price('standard', plan) }}
    WHEN 'ENTERPRISE' THEN {{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_edition_slot_price('enterprise', plan) }}
    WHEN 'ENTERPRISE_PLUS' THEN {{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_edition_slot_price('enterprise_plus', plan) }}
    WHEN 'ENTERPRISE PLUS' THEN {{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_edition_slot_price('enterprise_plus', plan) }}
    ELSE {{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_hourly_slot_price() }}
END
{% endmacro %}

{#-
  SQL expression for USD per slot-hour. With edition pricing off this is the
  numeric hourly_slot_price, so compiled SQL stays `* 0.04` by default.
-#}
{% macro dbt_bigquery_monitoring_slot_hour_price_sql(edition_sql='edition') -%}
    {%- if not dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_use_edition_slot_pricing() -%}
        {{- dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_hourly_slot_price() -}}
    {%- else -%}
        {%- set overrides = var('reservation_slot_pricing_plans', {}) -%}
        {%- if overrides is string or overrides is not mapping -%}
            {% do exceptions.raise_compiler_error(
                "reservation_slot_pricing_plans must be a mapping of reservation_id to slot_pricing_plan"
            ) %}
        {%- endif -%}
        {%- set global_plan = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_slot_pricing_plan() -%}
        {%- if overrides | length == 0 -%}
{{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_edition_price_case(global_plan, edition_sql) }}
        {%- else -%}
CASE
            {%- for reservation_id, reservation_plan in overrides.items() %}
    WHEN reservation_id = '{{ reservation_id | replace("'", "''") }}' THEN {{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_edition_price_case(reservation_plan, edition_sql) }}
            {%- endfor %}
    ELSE {{ dbt_bigquery_monitoring.dbt_bigquery_monitoring_edition_price_case(global_plan, edition_sql) }}
END
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
