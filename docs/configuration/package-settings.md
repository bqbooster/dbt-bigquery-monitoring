---
sidebar_position: 5.4
slug: /configuration/package-settings
---

# Customizing the package settings

This page is the full variable reference for the package.

- Start with the [configuration guide](/configuration) to pick your mode and enable data sources.
- Use the [configuration matrix](/configuration#configuration-matrix) to verify required and optional variables.
- Follow the [quickstart](/quickstart) for a first-run walkthrough.

Following settings can be overriden to customize the package configuration.
To do so, you can set the following variables in your `dbt_project.yml` file or use environment variables.

## Environment

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `input_gcp_projects` | `DBT_BQ_MONITORING_GCP_PROJECTS` | List of GCP projects to monitor | `[]` |
| `input_datasets` | `DBT_BQ_MONITORING_INPUT_DATASETS` | Optional `project.dataset` values that limit dataset-scanned `INFORMATION_SCHEMA` models | `[]` |
| `bq_region` | `DBT_BQ_MONITORING_REGION` | Region where the monitored projects are located | `us` |

### `input_datasets` examples

Use `input_datasets` when you want to skip automatic dataset discovery
for dataset-scanned `INFORMATION_SCHEMA` models. Set one
`project.dataset` string or a list of `project.dataset` values in
`dbt_project.yml`. If you leave it empty, the package auto-discovers
datasets.

If you use `DBT_BQ_MONITORING_INPUT_DATASETS`, pass a single
`project.dataset` string. List-style environment variable values are not
parsed for this setting, so use `dbt_project.yml` or `--vars` for
multiple datasets.

```yml
# dbt_project.yml
vars:
  input_datasets: 'sample-project.sample_dataset'
```

```yml
# dbt_project.yml
vars:
  input_datasets:
    - 'sample-project.sample_dataset'
    - 'sample-project.second_dataset'
```

## Pricing

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `use_flat_pricing` | `DBT_BQ_MONITORING_USE_FLAT_PRICING` | Whether to use flat pricing or not | `true` |
| `per_billed_tb_price` | `DBT_BQ_MONITORING_PER_BILLED_TB_PRICE` | Price in US dollars per billed TB of data processed | `6.25` |
| `free_tb_per_month` | `DBT_BQ_MONITORING_FREE_TB_PER_MONTH` | Free on demand compute quota TB per month | `1` |
| `hourly_slot_price` | `DBT_BQ_MONITORING_HOURLY_SLOT_PRICE` | Hourly price in US dollars per slot per hour. This is the rate used for every job while edition pricing is off | `0.04` |
| `use_edition_slot_pricing` | `DBT_BQ_MONITORING_USE_EDITION_SLOT_PRICING` | Price slot-hours from the job `edition` instead of `hourly_slot_price`. Off preserves the historical flat rate | `false` |
| `slot_pricing_plan` | `DBT_BQ_MONITORING_SLOT_PRICING_PLAN` | Plan used when edition pricing is on: `pay_as_you_go`, `commitment_1_year`, or `commitment_3_year` | `pay_as_you_go` |
| `standard_payg_slot_price` | `DBT_BQ_MONITORING_STANDARD_PAYG_SLOT_PRICE` | Standard edition pay-as-you-go USD per slot-hour | `0.04` |
| `standard_commitment_1y_slot_price` | `DBT_BQ_MONITORING_STANDARD_COMMITMENT_1Y_SLOT_PRICE` | Standard 1-year spend-based CUD USD per slot-hour. Standard has no slot commitment | `0.036` |
| `standard_commitment_3y_slot_price` | `DBT_BQ_MONITORING_STANDARD_COMMITMENT_3Y_SLOT_PRICE` | Standard 3-year spend-based CUD USD per slot-hour | `0.032` |
| `enterprise_payg_slot_price` | `DBT_BQ_MONITORING_ENTERPRISE_PAYG_SLOT_PRICE` | Enterprise edition pay-as-you-go USD per slot-hour | `0.06` |
| `enterprise_commitment_1y_slot_price` | `DBT_BQ_MONITORING_ENTERPRISE_COMMITMENT_1Y_SLOT_PRICE` | Enterprise 1-year resource commitment USD per slot-hour | `0.048` |
| `enterprise_commitment_3y_slot_price` | `DBT_BQ_MONITORING_ENTERPRISE_COMMITMENT_3Y_SLOT_PRICE` | Enterprise 3-year resource commitment USD per slot-hour | `0.036` |
| `enterprise_plus_payg_slot_price` | `DBT_BQ_MONITORING_ENTERPRISE_PLUS_PAYG_SLOT_PRICE` | Enterprise Plus pay-as-you-go USD per slot-hour | `0.10` |
| `enterprise_plus_commitment_1y_slot_price` | `DBT_BQ_MONITORING_ENTERPRISE_PLUS_COMMITMENT_1Y_SLOT_PRICE` | Enterprise Plus 1-year resource commitment USD per slot-hour | `0.08` |
| `enterprise_plus_commitment_3y_slot_price` | `DBT_BQ_MONITORING_ENTERPRISE_PLUS_COMMITMENT_3Y_SLOT_PRICE` | Enterprise Plus 3-year resource commitment USD per slot-hour | `0.06` |
| `active_logical_storage_gb_price` | `DBT_BQ_MONITORING_ACTIVE_LOGICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per active logical storage GB | `0.02` |
| `long_term_logical_storage_gb_price` | `DBT_BQ_MONITORING_LONG_TERM_LOGICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per long term logical storage GB | `0.01` |
| `active_physical_storage_gb_price` | `DBT_BQ_MONITORING_ACTIVE_PHYSICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per active physical storage GB | `0.04` |
| `long_term_physical_storage_gb_price` | `DBT_BQ_MONITORING_LONG_TERM_PHYSICAL_STORAGE_GB_PRICE` | Monthly price in US dollars per long term physical storage GB | `0.02` |
| `bi_engine_gb_hourly_price` | `DBT_BQ_MONITORING_BI_ENGINE_GB_HOURLY_PRICE` | Hourly price in US dollars per BI engine GB of memory | `0.0416` |
| `free_storage_gb_per_month` | `DBT_BQ_MONITORING_FREE_STORAGE_GB_PER_MONTH` | Free storage GB per month | `10` |

### Edition-aware slot pricing

This stays **off** unless you set `use_edition_slot_pricing`. While it is off, `flat_pricing_query_cost` is still `total_slot_ms / (1000 * 60 * 60) * hourly_slot_price`, and the compiled multiplier is the number `0.04` when you have not overridden `hourly_slot_price`. Column names, types, and costs do not change, and no full refresh is required.

Turn it on to price each job from `INFORMATION_SCHEMA.JOBS.edition`:

| Edition | `pay_as_you_go` | `commitment_1_year` | `commitment_3_year` |
|---------|-----------------|---------------------|---------------------|
| `STANDARD` | 0.04 | 0.036 | 0.032 |
| `ENTERPRISE` | 0.06 | 0.048 | 0.036 |
| `ENTERPRISE_PLUS` | 0.10 | 0.08 | 0.06 |

Defaults are US list prices (November 2026). Standard has no slot commitment, so its commitment columns are the 1-year and 3-year spend-based CUD rates. Enterprise and Enterprise Plus commitment columns are resource-commitment rates (20% and 40% off pay-as-you-go). Override any cell with the variable in the table above. `slot_pricing_plan` selects the column for every reservation.

`NULL`, on-demand, and any other edition use `hourly_slot_price`. In audit-log-only mode `edition` is an untyped null; the enabled expression casts it to `STRING` and takes that same fallback, so `jobs_with_cost` still compiles.

`reservation_slot_pricing_plans` is a **dbt var only** (a string environment variable cannot carry a mapping). Map `reservation_id` to a plan name. Other reservations use `slot_pricing_plan`.

```yml
vars:
  use_edition_slot_pricing: true
  slot_pricing_plan: pay_as_you_go
  reservation_slot_pricing_plans:
    "admin-project:US.etl": commitment_3_year
```

Enabling the flag does not alter table schemas. Incremental models keep previously written costs until those partitions are rebuilt. Run a full refresh of the downstream incremental models when you want history restated at the new rates.

## Package

These settings are used to configure how dbt will run and materialize the models.

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `lookback_window_days` | `DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS` | Number of days to look back for monitoring | `7` |
| `lookback_incremental_billing_window_days` | `DBT_BQ_MONITORING_LOOKBACK_INCREMENTAL_BILLING_WINDOW_DAYS` | Number of days to look back for monitoring | `3` |
| `output_limit_size` | `DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE` | Limit size to use for the models | `1000` |
| `output_partition_expiration_days` | `DBT_BQ_MONITORING_TABLE_EXPIRATION_DAYS` | Default table expiration in days for incremental models | `365` days |
| `use_copy_partitions` | `DBT_BQ_MONITORING_USE_COPY_PARTITIONS` | Whether to use copy partitions or not | `true` |
| `google_information_schema_model_materialization` | `DBT_BQ_MONITORING_GOOGLE_INFORMATION_SCHEMA_MODELS_MATERIALIZATION` | Whether to use a specific materialization for information schema models. Note that it doesn't work in project mode as it will materialize intermediate tables to avoid issues from BQ when too many projects are used. | `ephemeral` |
| `partitions_table_batch_size` | `DBT_BQ_MONITORING_PARTITIONS_TABLE_BATCH_SIZE` | Max tables per `INFORMATION_SCHEMA.PARTITIONS` query. BigQuery rejects scans of more than 1000 tables; the package lists tables and queries oversized datasets in batches. Defaults to 900 to stay under the limit. Datasets at or below this size keep a single unfiltered `PARTITIONS` query. | `900` |

### `INFORMATION_SCHEMA.PARTITIONS` 1000-table limit

[BigQuery limits `INFORMATION_SCHEMA.PARTITIONS` to 1000 tables per query](https://docs.cloud.google.com/bigquery/docs/information-schema-partitions). `input_datasets` only chooses which datasets are scanned, so it does not help when a needed dataset itself has more than 1000 tables.

By default `information_schema_partitions` uses the `information_schema_batched_table` materialization: it counts tables in each dataset, leaves small datasets as one unfiltered `SELECT`, and queries larger datasets with `WHERE table_name IN UNNEST([...])` in separate jobs (never `UNION ALL`'d in one statement). View or ephemeral overrides (`google_information_schema_model_materialization`) cannot split those jobs and will fail if any selected dataset needs batching.

Other dataset-scanned `INFORMATION_SCHEMA` models (`KEY_COLUMN_USAGE`, `CONSTRAINT_COLUMN_USAGE`, `SEARCH_INDEXES*`) do not document this 1000-table cap, so they are unchanged.

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
| `gcp_bigquery_audit_logs_table` | `DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_TABLE` | The table for BigQuery Audit logs data. See [audit logs configuration](/configuration/audit-logs) for details on which table to use | `cloudaudit_googleapis_com_data_access` |
| `should_combine_audit_logs_and_information_schema` | `DBT_BQ_MONITORING_SHOULD_COMBINE_AUDIT_LOGS_AND_INFORMATION_SCHEMA` | Whether to combine the audit logs and information schema data | `false` |
| `google_information_schema_model_materialization` | `DBT_BQ_MONITORING_GOOGLE_INFORMATION_SCHEMA_MODELS_MATERIALIZATION` | Whether to use a specific materialization for information schema models. Note that it doesn't work in project mode as it will materialize intermediate tables to avoid issues from BQ when too many projects are used. | `ephemeral` |

### Experimental / Preview fields

BigQuery periodically introduces new fields in `INFORMATION_SCHEMA` views that are initially in "Preview" or "Experimental" and might not be available in all regions. These fields are disabled by default in this package to ensure compatibility across all regions.

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `enable_experimental_fields` | `DBT_BQ_MONITORING_ENABLE_EXPERIMENTAL_FIELDS` | Toggle to enable all experimental/preview fields | `true` |
| `enable_principal_subject` | `DBT_BQ_MONITORING_ENABLE_PRINCIPAL_SUBJECT` | Toggle to enable `principal_subject` field in jobs views | `true` |
| `enable_reservation_group_path` | `DBT_BQ_MONITORING_ENABLE_RESERVATION_GROUP_PATH` | Toggle to enable `reservation_group_path` field in reservations views | `false` |
| `enable_total_services_sku_slot_ms` | `DBT_BQ_MONITORING_ENABLE_TOTAL_SERVICES_SKU_SLOT_MS` | Toggle to enable `total_services_sku_slot_ms` field in jobs views | `true` |
| `enable_materialized_view_statistics` | `DBT_BQ_MONITORING_ENABLE_MATERIALIZED_VIEW_STATISTICS` | Toggle to enable `materialized_view_statistics` field in jobs views | `true` |
