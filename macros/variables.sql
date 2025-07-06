{% macro dbt_bigquery_monitoring_variable_priority(dbt_variable_name, environment_variable_name, default_value) %}
    {% set dbt_variable_value = var(dbt_variable_name, 'placeholder') %}
    {% set environment_variable_value = env_var(environment_variable_name, 'placeholder') %}

    {% if environment_variable_value != 'placeholder' %}
        {{ return(environment_variable_value) }}
    {% elif dbt_variable_value != 'placeholder' %}
        {{ return(dbt_variable_value) }}
    {% else %}
        {{ return(default_value) }}
    {% endif %}
{% endmacro %}

{% macro force_bool(value) %}
    {% if value == 'true' %}
        {{ return(true) }}
    {% elif value == 'false' %}
        {{ return(false) }}
    {% else %}
        {{ return(value) }}
    {% endif %}
{% endmacro %}

/* ==============================================
   GCP PROJECT AND REGION CONFIGURATION
   ============================================== */

{% macro dbt_bigquery_monitoring_variable_bq_region() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('bq_region', 'DBT_BQ_MONITORING_REGION', 'us')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_input_gcp_projects() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('input_gcp_projects', 'DBT_BQ_MONITORING_GCP_PROJECTS', [])) }}
{% endmacro %}

/* ==============================================
   BIGQUERY PRICING CONFIGURATION
   ============================================== */

/* On-demand compute (analysis) pricing */
{% macro dbt_bigquery_monitoring_variable_use_flat_pricing() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('use_flat_pricing', 'DBT_BQ_MONITORING_USE_FLAT_PRICING', true))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_per_billed_tb_price() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('per_billed_tb_price', 'DBT_BQ_MONITORING_PER_BILLED_TB_PRICE', 6.25) | as_number) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_free_tb_per_month() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('free_tb_per_month', 'DBT_BQ_MONITORING_FREE_TB_PER_MONTH', 1) | as_number) }}
{% endmacro %}

/* Capacity compute (analysis) pricing */
{% macro dbt_bigquery_monitoring_variable_hourly_slot_price() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('hourly_slot_price', 'DBT_BQ_MONITORING_HOURLY_SLOT_PRICE', 0.04) | as_number) }}
{% endmacro %}

/* Storage pricing */
{% macro dbt_bigquery_monitoring_variable_active_logical_storage_gb_price() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('active_logical_storage_gb_price', 'DBT_BQ_MONITORING_ACTIVE_LOGICAL_STORAGE_GB_PRICE', 0.02) | as_number) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_long_term_logical_storage_gb_price() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('long_term_logical_storage_gb_price', 'DBT_BQ_MONITORING_LONG_TERM_LOGICAL_STORAGE_GB_PRICE', 0.01) | as_number) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_active_physical_storage_gb_price() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('active_physical_storage_gb_price', 'DBT_BQ_MONITORING_ACTIVE_PHYSICAL_STORAGE_GB_PRICE', 0.04) | as_number) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_long_term_physical_storage_gb_price() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('long_term_physical_storage_gb_price', 'DBT_BQ_MONITORING_LONG_TERM_PHYSICAL_STORAGE_GB_PRICE', 0.02) | as_number) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_free_storage_gb_per_month() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('free_storage_gb_per_month', 'DBT_BQ_MONITORING_FREE_STORAGE_GB_PER_MONTH', 10) | as_number) }}
{% endmacro %}

/* BI Engine pricing */
{% macro dbt_bigquery_monitoring_variable_bi_engine_gb_hourly_price() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('bi_engine_gb_hourly_price', 'DBT_BQ_MONITORING_BI_ENGINE_GB_HOURLY_PRICE', 0.0416) | as_number) }}
{% endmacro %}

/* ==============================================
   TIME WINDOW CONFIGURATION
   ============================================== */

/* The number of days to look back for regular tables, you might use up to 180 days usually */
{% macro dbt_bigquery_monitoring_variable_lookback_window_days() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('lookback_window_days', 'DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS', 7) | as_number) }}
{% endmacro %}

/* Billing data can be late, a safe window is to refresh data for the past 3 days */
{% macro dbt_bigquery_monitoring_variable_lookback_incremental_billing_window_days() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('lookback_incremental_billing_window_days', 'DBT_BQ_MONITORING_LOOKBACK_INCREMENTAL_BILLING_WINDOW_DAYS', 3) | as_number) }}
{% endmacro %}

/* ==============================================
   PROJECT OUTPUT CONFIGURATION
   ============================================== */

{% macro dbt_bigquery_monitoring_variable_output_materialization() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('output_materialization', 'DBT_BQ_MONITORING_OUTPUT_MATERIALIZATION', 'table')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_output_limit_size() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('output_limit_size', 'DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE', 1000) | as_number) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_output_partition_expiration_days() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('output_partition_expiration_days', 'DBT_BQ_MONITORING_TABLE_EXPIRATION_DAYS', 365) | as_number) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_use_copy_partitions() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('use_copy_partitions', 'DBT_BQ_MONITORING_USE_COPY_PARTITIONS', true))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_google_information_schema_model_materialization() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('google_information_schema_model_materialization', 'DBT_BQ_MONITORING_GOOGLE_INFORMATION_SCHEMA_MODELS_MATERIALIZATION', 'placeholder')) }}
{% endmacro %}

/* ==============================================
   GCP BILLING EXPORT CONFIGURATION
   Required for storage cost monitoring over time
   ============================================== */

{% macro dbt_bigquery_monitoring_variable_enable_gcp_billing_export() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('enable_gcp_billing_export', 'DBT_BQ_MONITORING_ENABLE_GCP_BILLING_EXPORT', false))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_gcp_billing_export_storage_project() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('gcp_billing_export_storage_project', 'DBT_BQ_MONITORING_GCP_BILLING_EXPORT_STORAGE_PROJECT', 'placeholder')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_gcp_billing_export_dataset() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('gcp_billing_export_dataset', 'DBT_BQ_MONITORING_GCP_BILLING_EXPORT_DATASET', 'placeholder')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_gcp_billing_export_table() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('gcp_billing_export_table', 'DBT_BQ_MONITORING_GCP_BILLING_EXPORT_TABLE', 'placeholder')) }}
{% endmacro %}

/* ==============================================
   GCP BIGQUERY AUDIT LOGS CONFIGURATION
   Alternative to INFORMATION_SCHEMA.JOBS
   ============================================== */

{% macro dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('enable_gcp_bigquery_audit_logs', 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS', false))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_storage_project() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('gcp_bigquery_audit_logs_storage_project', 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_STORAGE_PROJECT', 'placeholder')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_dataset() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('gcp_bigquery_audit_logs_dataset', 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_DATASET', 'placeholder')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_table() %}
    {{ return(dbt_bigquery_monitoring_variable_priority('gcp_bigquery_audit_logs_table', 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_TABLE', 'placeholder')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_should_combine_audit_logs_and_information_schema() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('should_combine_audit_logs_and_information_schema', 'DBT_BQ_MONITORING_SHOULD_COMBINE_AUDIT_LOGS_AND_INFORMATION_SCHEMA', false))) }}
{% endmacro %}
