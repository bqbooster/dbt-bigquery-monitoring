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
  # dbt bigquery monitoring vars
  bq_region: 'us'
  input_gcp_projects: [ 'my-gcp-project', 'my-gcp-project-2' ]
```

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

### Customizing the package configuration

Settings details

Following settings are defined with following template: `dbt_project_variable` (__Environment variable__) : description (default if any).

### Optional settings

#### Environment

- `input_gcp_projects` (__DBT_BQ_MONITORING_GCP_PROJECTS__) : list of GCP projects to monitor (default: `[]`)
- `bq_region` (__DBT_BQ_MONITORING_REGION__) : region where the monitored projects are located (default: `us`)

#### Pricing

- `use_flat_pricing` (__DBT_BQ_MONITORING_USE_FLAT_PRICING__) : whether to use flat pricing or not (default: `true`)
- `per_billed_tb_price` (__DBT_BQ_MONITORING_PER_BILLED_TB_PRICE__) : price in US dollars per billed TB of data processed (default: `6,25`)
- `free_tb_per_month` (__DBT_BQ_MONITORING_FREE_TB_PER_MONTH__) : free on demand compute quota TB per month (default: `1`)
- `hourly_slot_price` (__DBT_BQ_MONITORING_HOURLY_SLOT_PRICE__) : hourly price in US dollars per slot per hour (default: `0.04`)
- `active_logical_storage_gb_price` (__DBT_BQ_MONITORING_ACTIVE_LOGICAL_STORAGE_GB_PRICE__) : monthly price in US dollars per active logical storage GB (default: `0.02`)
- `long_term_logical_storage_gb_price` (__DBT_BQ_MONITORING_LONG_TERM_LOGICAL_STORAGE_GB_PRICE__) : monthly price in US dollars per long term logical storage GB (default: `0.01`)
- `active_physical_storage_gb_price` (__DBT_BQ_MONITORING_ACTIVE_PHYSICAL_STORAGE_GB_PRICE__) : monthly price in US dollars per active physical storage GB (default: `0.04`)
- `long_term_physical_storage_gb_price` (__DBT_BQ_MONITORING_LONG_TERM_PHYSICAL_STORAGE_GB_PRICE__) : monthly price in US dollars per long term physical storage GB (default: `0.02`)
- `bi_engine_gb_hourly_price` (__DBT_BQ_MONITORING_BI_ENGINE_GB_HOURLY_PRICE__): hourly price in US dollars per BI engine GB of memory (default: `0.0416`)
- `free_storage_gb_per_month` (__DBT_BQ_MONITORING_FREE_STORAGE_GB_PER_MONTH__) : free storage GB per month (default: `10`)

#### Package

- `lookback_window_days` (__DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS__) : number of days to look back for monitoring (default: `7`)
- `lookback_incremental_billing_window_days` (__DBT_BQ_MONITORING_LOOKBACK_INCREMENTAL_BILLING_WINDOW_DAYS__) : number of days to look back for monitoring (default: `3`)
- `output_limit_size` (__DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE__) : limit size to use for the models (default: `1000`)
- `output_partition_expiration_days` (__DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE__) : default table expiration in days for incremental models (default: `365` days)
- `use_copy_partitions` (__DBT_BQ_MONITORING_USE_COPY_PARTITIONS__) : whether to use copy partitions or not (default: `true`)

#### GCP Billing export
- `enable_gcp_billing_export` (__DBT_BQ_MONITORING_ENABLE_GCP_BILLING_EXPORT__) : toggle to enable GCP billing export monitoring (default: `false`)
- `gcp_billing_export_storage_project` (__DBT_BQ_MONITORING_GCP_BILLING_EXPORT_STORAGE_PROJECT__) : the GCP project where billing export data is stored (default: `'placeholder'` if `enable_gcp_billing_export` is `true`; otherwise `None`)
- `gcp_billing_export_dataset` (__DBT_BQ_MONITORING_GCP_BILLING_EXPORT_DATASET__) : the dataset for GCP billing export data (default: `'placeholder'` if `enable_gcp_billing_export` is `true`; otherwise `None`)
- `gcp_billing_export_table` (__DBT_BQ_MONITORING_GCP_BILLING_EXPORT_TABLE__) : the table for GCP billing export data (default: `'placeholder'` if `enable_gcp_billing_export` is `true`; otherwise `None`)

### Add metadata to queries (Recommended but optional)

To enhance your query metadata with dbt model information, the package provides a dedicated macro that leverage "dbt query comments" (the header set at the top of each query)
To configure the query comments, add the following config to `dbt_project.yml`.

```yaml
query-comment:
  comment: '{{ dbt_bigquery_monitoring.get_query_comment(node) }}'
  job-label: True # Use query comment JSON as job labels
```
