---
sidebar_position: 4.4
slug: /configuration/package-settings
---

# Customizing the package settings

Following settings can be overriden to customize the package configuration.
To do so, you can set the following variables in your `dbt_project.yml` file or use environment variables.

## Environment

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `input_gcp_projects` | `DBT_BQ_MONITORING_GCP_PROJECTS` | List of GCP projects to monitor | `[]` |
| `bq_region` | `DBT_BQ_MONITORING_REGION` | Region where the monitored projects are located | `us` |

## Pricing

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `use_flat_pricing` | `DBT_BQ_MONITORING_USE_FLAT_PRICING` | Whether to use flat pricing or not | `true` |
| `per_billed_tb_price` | `DBT_BQ_MONITORING_PER_BILLED_TB_PRICE` | Price in US dollars per billed TB of data processed | `6.25` |
| `free_tb_per_month` | `DBT_BQ_MONITORING_FREE_TB_PER_MONTH` | Free on demand compute quota TB per month | `1` |
| `hourly_slot_price` | `DBT_BQ_MONITORING_HOURLY_SLOT_PRICE` | Hourly price in US dollars per slot per hour | `0.04` |
| `active_logical_storage_gb_price` | `DBT_BQ_MONITORING_ACTIVE_LOGICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per active logical storage GB | `0.02` |
| `long_term_logical_storage_gb_price` | `DBT_BQ_MONITORING_LONG_TERM_LOGICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per long term logical storage GB | `0.01` |
| `active_physical_storage_gb_price` | `DBT_BQ_MONITORING_ACTIVE_PHYSICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per active physical storage GB | `0.04` |
| `long_term_physical_storage_gb_price` | `DBT_BQ_MONITORING_LONG_TERM_PHYSICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per long term physical storage GB | `0.02` |
| `bi_engine_gb_hourly_price` | `DBT_BQ_MONITORING_BI_ENGINE_GB_HOURLY_PRICE` | Hourly price in US dollars per BI engine GB of memory | `0.0416` |
| `free_storage_gb_per_month` | `DBT_BQ_MONITORING_FREE_STORAGE_GB_PER_MONTH` | Free storage GB per month | `10` |

## Package

These settings are used to configure how dbt will run and materialize the models.

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `lookback_window_days` | `DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS` | Number of days to look back for monitoring | `7` |
| `lookback_incremental_billing_window_days` | `DBT_BQ_MONITORING_LOOKBACK_INCREMENTAL_BILLING_WINDOW_DAYS` | Number of days to look back for monitoring | `3` |
| `output_limit_size` | `DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE` | Limit size to use for the models | `1000` |
| `output_partition_expiration_days` | `DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE` | Default table expiration in days for incremental models | `365` days |
| `use_copy_partitions` | `DBT_BQ_MONITORING_USE_COPY_PARTITIONS` | Whether to use copy partitions or not | `true` |
| `google_information_schema_model_materialization` | `DBT_BQ_MONITORING_GOOGLE_INFORMATION_SCHEMA_MODELS_MATERIALIZATION` | Whether to use a specific materialization for information schema models. Note that it doesn't work in project mode as it will materialize intermediate tables to avoid issues from BQ when too many projects are used. | `ephemeral` |

### GCP Billing export configuration

See [GCP Billing export](/configuration/gcp-billing) for more information.

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `enable_gcp_billing_export` | `DBT_BQ_MONITORING_ENABLE_GCP_BILLING_EXPORT` | Toggle to enable GCP billing export monitoring | `false` |
| `gcp_billing_export_storage_project` | `DBT_BQ_MONITORING_GCP_BILLING_EXPORT_STORAGE_PROJECT` | The GCP project where billing export data is stored | `'placeholder'` if enabled, `None` otherwise |
| `gcp_billing_export_dataset` | `DBT_BQ_MONITORING_GCP_BILLING_EXPORT_DATASET` | The dataset for GCP billing export data | `'placeholder'` if enabled, `None` otherwise |
| `gcp_billing_export_table` | `DBT_BQ_MONITORING_GCP_BILLING_EXPORT_TABLE` | The table for GCP billing export data | `'placeholder'` if enabled, `None` otherwise |

### GCP BigQuery Audit logs configuration

See [GCP BigQuery Audit logs](/configuration/audit-logs) for more information.

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `enable_gcp_bigquery_audit_logs` | `DBT_BQ_MONITORING_ENABLE_GCP_BIGQUERY_AUDIT_LOGS` | Toggle to enable GCP BigQuery Audit logs monitoring | `false` |
| `gcp_bigquery_audit_logs_storage_project` | `DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_STORAGE_PROJECT` | The GCP project where BigQuery Audit logs data is stored | `'placeholder'` if enabled, `None` otherwise |
| `gcp_bigquery_audit_logs_dataset` | `DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_DATASET` | The dataset for BigQuery Audit logs data | `'placeholder'` if enabled, `None` otherwise |
| `gcp_bigquery_audit_logs_table` | `DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_TABLE` | The table for BigQuery Audit logs data | `'placeholder'` if enabled, `None` otherwise |
| `should_combine_audit_logs_and_information_schema` | `DBT_BQ_MONITORING_SHOULD_COMBINE_AUDIT_LOGS_AND_INFORMATION_SCHEMA` | Whether to combine the audit logs and information schema data | `false` |
