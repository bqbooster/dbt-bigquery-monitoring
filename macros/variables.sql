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
    {% if value == 'true' or value == true %}
        {{ return(true) }}
    {% elif value == 'false' or value == false %}
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
    {{ return(dbt_bigquery_monitoring_variable_priority('gcp_bigquery_audit_logs_table', 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_TABLE', 'cloudaudit_googleapis_com_activity')) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_should_combine_audit_logs_and_information_schema() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('should_combine_audit_logs_and_information_schema', 'DBT_BQ_MONITORING_SHOULD_COMBINE_AUDIT_LOGS_AND_INFORMATION_SCHEMA', false))) }}
{% endmacro %}

/* ==============================================
   EXPERIMENTAL / PREVIEW FIELDS CONFIGURATION
   ============================================== */

{% macro dbt_bigquery_monitoring_variable_enable_experimental_fields() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('enable_experimental_fields', 'DBT_BQ_MONITORING_ENABLE_EXPERIMENTAL_FIELDS', false))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_enable_preview_fields() %}
    {{ return(dbt_bigquery_monitoring_variable_enable_experimental_fields()) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_enable_principal_subject() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('enable_principal_subject', 'DBT_BQ_MONITORING_ENABLE_PRINCIPAL_SUBJECT', dbt_bigquery_monitoring_variable_enable_experimental_fields()))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_enable_reservation_group_path() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('enable_reservation_group_path', 'DBT_BQ_MONITORING_ENABLE_RESERVATION_GROUP_PATH', dbt_bigquery_monitoring_variable_enable_experimental_fields()))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_enable_materialized_view_statistics() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('enable_materialized_view_statistics', 'DBT_BQ_MONITORING_ENABLE_MATERIALIZED_VIEW_STATISTICS', dbt_bigquery_monitoring_variable_enable_experimental_fields()))) }}
{% endmacro %}

{% macro dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms() %}
    {{ return(force_bool(dbt_bigquery_monitoring_variable_priority('enable_total_services_sku_slot_ms', 'DBT_BQ_MONITORING_ENABLE_TOTAL_SERVICES_SKU_SLOT_MS', dbt_bigquery_monitoring_variable_enable_experimental_fields()))) }}
{% endmacro %}

{% macro get_variable_resolution_info(dbt_var_name, env_var_name, default_value) %}
    {% set env_var = env_var(env_var_name, 'NOT_SET') %}
    {% set dbt_var = var(dbt_var_name, 'NOT_SET') %}

    {% if env_var != 'NOT_SET' %}
        {% set resolution = 'environment variable: ' + env_var_name %}
        {% set value = env_var %}
    {% elif dbt_var != 'NOT_SET' %}
        {% set resolution = 'dbt variable: ' + dbt_var_name %}
        {% set value = dbt_var %}
    {% else %}
        {% set resolution = 'default value' %}
        {% set value = default_value %}
    {% endif %}

    {% set result = {'value': value, 'resolution': resolution} %}
    {{ return(result) }}
{% endmacro %}

{% macro debug_dbt_bigquery_monitoring_variables() %}
    {{ log("[dbt-bigquery-monitoring] === DBT BigQuery Monitoring Variables Debug ===", info=True) }}

    {# Define variables configuration for debugging #}
    {% set variable_configs = [
        {'dbt_var': 'bq_region', 'env_var': 'DBT_BQ_MONITORING_REGION', 'default': 'us', 'format': 'string'},
        {'dbt_var': 'input_gcp_projects', 'env_var': 'DBT_BQ_MONITORING_GCP_PROJECTS', 'default': [], 'format': 'string'},
        {'dbt_var': 'use_flat_pricing', 'env_var': 'DBT_BQ_MONITORING_USE_FLAT_PRICING', 'default': true, 'format': 'string'},
        {'dbt_var': 'per_billed_tb_price', 'env_var': 'DBT_BQ_MONITORING_PER_BILLED_TB_PRICE', 'default': 6.25, 'format': 'string'},
        {'dbt_var': 'free_tb_per_month', 'env_var': 'DBT_BQ_MONITORING_FREE_TB_PER_MONTH', 'default': 1, 'format': 'string'},
        {'dbt_var': 'hourly_slot_price', 'env_var': 'DBT_BQ_MONITORING_HOURLY_SLOT_PRICE', 'default': 0.04, 'format': 'string'},
        {'dbt_var': 'active_logical_storage_gb_price', 'env_var': 'DBT_BQ_MONITORING_ACTIVE_LOGICAL_STORAGE_GB_PRICE', 'default': 0.02, 'format': 'string'},
        {'dbt_var': 'long_term_logical_storage_gb_price', 'env_var': 'DBT_BQ_MONITORING_LONG_TERM_LOGICAL_STORAGE_GB_PRICE', 'default': 0.01, 'format': 'string'},
        {'dbt_var': 'active_physical_storage_gb_price', 'env_var': 'DBT_BQ_MONITORING_ACTIVE_PHYSICAL_STORAGE_GB_PRICE', 'default': 0.04, 'format': 'string'},
        {'dbt_var': 'long_term_physical_storage_gb_price', 'env_var': 'DBT_BQ_MONITORING_LONG_TERM_PHYSICAL_STORAGE_GB_PRICE', 'default': 0.02, 'format': 'string'},
        {'dbt_var': 'free_storage_gb_per_month', 'env_var': 'DBT_BQ_MONITORING_FREE_STORAGE_GB_PER_MONTH', 'default': 10, 'format': 'string'},
        {'dbt_var': 'bi_engine_gb_hourly_price', 'env_var': 'DBT_BQ_MONITORING_BI_ENGINE_GB_HOURLY_PRICE', 'default': 0.0416, 'format': 'string'},
        {'dbt_var': 'lookback_window_days', 'env_var': 'DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS', 'default': 7, 'format': 'string'},
        {'dbt_var': 'lookback_incremental_billing_window_days', 'env_var': 'DBT_BQ_MONITORING_LOOKBACK_INCREMENTAL_BILLING_WINDOW_DAYS', 'default': 3, 'format': 'string'},
        {'dbt_var': 'output_materialization', 'env_var': 'DBT_BQ_MONITORING_OUTPUT_MATERIALIZATION', 'default': 'table', 'format': 'string'},
        {'dbt_var': 'output_limit_size', 'env_var': 'DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE', 'default': 1000, 'format': 'string'},
        {'dbt_var': 'output_partition_expiration_days', 'env_var': 'DBT_BQ_MONITORING_TABLE_EXPIRATION_DAYS', 'default': 365, 'format': 'string'},
        {'dbt_var': 'use_copy_partitions', 'env_var': 'DBT_BQ_MONITORING_USE_COPY_PARTITIONS', 'default': true, 'format': 'string'},
        {'dbt_var': 'google_information_schema_model_materialization', 'env_var': 'DBT_BQ_MONITORING_GOOGLE_INFORMATION_SCHEMA_MODELS_MATERIALIZATION', 'default': 'placeholder', 'format': 'string'},
        {'dbt_var': 'enable_gcp_billing_export', 'env_var': 'DBT_BQ_MONITORING_ENABLE_GCP_BILLING_EXPORT', 'default': false, 'format': 'string'},
        {'dbt_var': 'gcp_billing_export_storage_project', 'env_var': 'DBT_BQ_MONITORING_GCP_BILLING_EXPORT_STORAGE_PROJECT', 'default': 'placeholder', 'format': 'string'},
        {'dbt_var': 'gcp_billing_export_dataset', 'env_var': 'DBT_BQ_MONITORING_GCP_BILLING_EXPORT_DATASET', 'default': 'placeholder', 'format': 'string'},
        {'dbt_var': 'gcp_billing_export_table', 'env_var': 'DBT_BQ_MONITORING_GCP_BILLING_EXPORT_TABLE', 'default': 'placeholder', 'format': 'string'},
        {'dbt_var': 'enable_gcp_bigquery_audit_logs', 'env_var': 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS', 'default': false, 'format': 'string'},
        {'dbt_var': 'gcp_bigquery_audit_logs_storage_project', 'env_var': 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_STORAGE_PROJECT', 'default': 'placeholder', 'format': 'string'},
        {'dbt_var': 'gcp_bigquery_audit_logs_dataset', 'env_var': 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_DATASET', 'default': 'placeholder', 'format': 'string'},
        {'dbt_var': 'gcp_bigquery_audit_logs_table', 'env_var': 'DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_TABLE', 'default': 'placeholder', 'format': 'string'},
        {'dbt_var': 'should_combine_audit_logs_and_information_schema', 'env_var': 'DBT_BQ_MONITORING_SHOULD_COMBINE_AUDIT_LOGS_AND_INFORMATION_SCHEMA', 'default': false, 'format': 'string'},
        {'dbt_var': 'enable_experimental_fields', 'env_var': 'DBT_BQ_MONITORING_ENABLE_EXPERIMENTAL_FIELDS', 'default': false, 'format': 'string'},
        {'dbt_var': 'enable_principal_subject', 'env_var': 'DBT_BQ_MONITORING_ENABLE_PRINCIPAL_SUBJECT', 'default': false, 'format': 'string'},
        {'dbt_var': 'enable_reservation_group_path', 'env_var': 'DBT_BQ_MONITORING_ENABLE_RESERVATION_GROUP_PATH', 'default': false, 'format': 'string'},
        {'dbt_var': 'enable_total_services_sku_slot_ms', 'env_var': 'DBT_BQ_MONITORING_ENABLE_TOTAL_SERVICES_SKU_SLOT_MS', 'default': false, 'format': 'string'},
        {'dbt_var': 'enable_materialized_view_statistics', 'env_var': 'DBT_BQ_MONITORING_ENABLE_MATERIALIZED_VIEW_STATISTICS', 'default': false, 'format': 'string'}
    ] %}

    {# Loop through all variables and log their resolution info #}
    {% for config in variable_configs %}
        {% set var_info = get_variable_resolution_info(config.dbt_var, config.env_var, config.default) %}
        {{ log("[dbt-bigquery-monitoring] " + config.dbt_var + ": " + var_info.value | string + " (resolved from " + var_info.resolution + ")", info=True) }}
    {% endfor %}

    {{ log("[dbt-bigquery-monitoring] === End Debug ===", info=True) }}

{% endmacro %}
