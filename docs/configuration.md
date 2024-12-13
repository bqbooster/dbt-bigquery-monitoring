---
sidebar_position: 4
slug: /configuration
---

# Configuration

Settings have default values that can be overriden using:

- dbt project variables (and therefore also by CLI variable override)
- environment variables

Please note that the default region is `us` and there's no way, at the time of writing, to query cross region tables but you might run that project in each region you want to monitor and [then replicate the tables to a central region](https://cloud.google.com/bigquery/docs/data-replication) to build an aggregated view.

To know which region is related to a job, in the BQ UI, use the `Job history` (bottom panel), take a job and look at `Location` field when clicking on a job. You can also access the region of a dataset/table by opening the details panel of it and check the `Data location` field.

## Modes

### Region mode (default)

In this mode, the package will monitor all the GCP projects in the region specified in the `dbt_project.yml` file.

```yml
vars:
  # dbt bigquery monitoring vars
  bq_region: 'us'
```

**Requirements**

- Execution project needs to be the same as the storage project else you'll need to use the second mode.
- If you have multiple GCP Projects in the same region, you should use the "project mode" (with `input_gcp_projects` setting to specify them) as else you will run into errors such as: `Within a standard SQL view, references to tables/views require explicit project IDs unless the entity is created in the same project that is issuing the query, but these references are not project-qualified: "region-us.INFORMATION_SCHEMA.JOBS"`.

### Project mode

To enable the "project mode", you'll need to define explicitly one mandatory setting to set in the `dbt_project.yml` file:

```yml
vars:
  enable_gcp_bigquery_audit_logs: true
  gcp_bigquery_audit_logs_storage_project: 'my-gcp-project'
  gcp_bigquery_audit_logs_dataset: 'my_dataset'
  gcp_bigquery_audit_logs_table: 'my_table'
```



### BigQuery audit logs mode

In this mode, the package will monitor all the jobs that written to a GCP BigQuery Audit logs table instead of using `INFORMATION_SCHEMA.JOBS` one.

To enable the "cloud audit logs mode", you'll need to define explicitly one mandatory setting to set in the `dbt_project.yml` file:

```yml
vars:
  # dbt bigquery monitoring vars
  bq_region: 'us'
  cloud_audit_logs_table: 'my-gcp-project.my_dataset.my_table'
```

[You might use environment variable as well](#gcp-bigquery-audit-logs-configuration).

### GCP Billing export

GCP Billing export is a feature that allows you to export your billing data to BigQuery. It allows the package to track the real cost of your queries and storage overtime.

To enable on GCP end, you can follow the [official documentation](https://cloud.google.com/billing/docs/how-to/export-data-bigquery) to set up the export.

Then enable the GCP billing export monitoring in the package, you'll need to define the following settings in the `dbt_project.yml` file:

```yml
vars:
  # dbt bigquery monitoring vars
  enable_gcp_billing_export: true
  gcp_billing_export_storage_project: 'my-gcp-project'
  gcp_billing_export_dataset: 'my_dataset'
  gcp_billing_export_table: 'my_table'
```

## Add metadata to queries (Recommended but optional)

To enhance your query metadata with dbt model information, the package provides a dedicated macro that leverage "dbt query comments" (the header set at the top of each query)
To configure the query comments, add the following config to `dbt_project.yml`.

```yaml
query-comment:
  comment: '{{ dbt_bigquery_monitoring.get_query_comment(node) }}'
  job-label: True # Use query comment JSON as job labels
```

## Customizing the package configuration

Following settings can be overriden to customize the package configuration.
To do so, you can set the following variables in your `dbt_project.yml` file or use environment variables.

### Environment

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `input_gcp_projects` | `DBT_BQ_MONITORING_GCP_PROJECTS` | List of GCP projects to monitor | `[]` |
| `bq_region` | `DBT_BQ_MONITORING_REGION` | Region where the monitored projects are located | `us` |

### Pricing

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

### Package

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `lookback_window_days` | `DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS` | Number of days to look back for monitoring | `7` |
| `lookback_incremental_billing_window_days` | `DBT_BQ_MONITORING_LOOKBACK_INCREMENTAL_BILLING_WINDOW_DAYS` | Number of days to look back for monitoring | `3` |
| `output_limit_size` | `DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE` | Limit size to use for the models | `1000` |
| `output_partition_expiration_days` | `DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE` | Default table expiration in days for incremental models | `365` days |
| `use_copy_partitions` | `DBT_BQ_MONITORING_USE_COPY_PARTITIONS` | Whether to use copy partitions or not | `true` |

#### GCP Billing export configuration

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `enable_gcp_billing_export` | `DBT_BQ_MONITORING_ENABLE_GCP_BILLING_EXPORT` | Toggle to enable GCP billing export monitoring | `false` |
| `gcp_billing_export_storage_project` | `DBT_BQ_MONITORING_GCP_BILLING_EXPORT_STORAGE_PROJECT` | The GCP project where billing export data is stored | `'placeholder'` if enabled, `None` otherwise |
| `gcp_billing_export_dataset` | `DBT_BQ_MONITORING_GCP_BILLING_EXPORT_DATASET` | The dataset for GCP billing export data | `'placeholder'` if enabled, `None` otherwise |
| `gcp_billing_export_table` | `DBT_BQ_MONITORING_GCP_BILLING_EXPORT_TABLE` | The table for GCP billing export data | `'placeholder'` if enabled, `None` otherwise |

#### GCP BigQuery Audit logs configuration

See [GCP BigQuery Audit logs](#bigquery-audit-logs-mode) for more information.

| Variable | Environment Variable | Description | Default |
|----------|-------------------|-------------|---------|
| `enable_gcp_bigquery_audit_logs` | `DBT_BQ_MONITORING_ENABLE_GCP_BIGQUERY_AUDIT_LOGS` | Toggle to enable GCP BigQuery Audit logs monitoring | `false` |
| `gcp_bigquery_audit_logs_storage_project` | `DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_STORAGE_PROJECT` | The GCP project where BigQuery Audit logs data is stored | `'placeholder'` if enabled, `None` otherwise |
| `gcp_bigquery_audit_logs_dataset` | `DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_DATASET` | The dataset for BigQuery Audit logs data | `'placeholder'` if enabled, `None` otherwise |
| `gcp_bigquery_audit_logs_table` | `DBT_BQ_MONITORING_GCP_BIGQUERY_AUDIT_LOGS_TABLE` | The table for BigQuery Audit logs data | `'placeholder'` if enabled, `None` otherwise |
| `should_combine_audit_logs_and_information_schema` | `DBT_BQ_MONITORING_SHOULD_COMBINE_AUDIT_LOGS_AND_INFORMATION_SCHEMA` | Whether to combine the audit logs and information schema data | `false` |
