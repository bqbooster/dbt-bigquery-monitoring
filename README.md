# dbt-bigquery-monitoring

🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧

**This package is still in development and is not ready for production use.**

🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧

dbt-bigquery-monitoring is a dbt package that provides models for monitoring BigQuery performance and costs.

## Get started

### Granting rights

To use this package, you will need to grant the following permissions to the Service Account that dbt uses to connect to BigQuery:

- **bigquery.`TABLES`.get** - To [access BigQuery tables data](https://cloud.google.com/bigquery/docs/information-schema-table-storage#required_permissions)
- **bigquery.`TABLES`.list** - To [access BigQuery tables data](https://cloud.google.com/bigquery/docs/information-schema-table-storage#required_permissions)
- **bigquery.jobs.listAll**
  - At the organization or project level, depending on desired scope
  - Note that JOBS_BY_ORGANIZATION is only available to users with defined Google Cloud organizations. More information on permissions and access control in BigQuery can be found [here](https://cloud.google.com/bigquery/docs/access-control).
- **bigquery.reservations.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- **bigquery.capacityCommitments.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- **bigquery.reservationAssignments.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)

The required permissions (listed above) are available to:

- [`BigQuery Resource Admin`](https://cloud.google.com/bigquery/docs/access-control#bigquery.resourceAdmin)
- [`BigQuery Admin`](https://cloud.google.com/bigquery/docs/access-control#bigquery.admin) roles but feel free to create a custom role.

### Installing the package to your dbt project

Add the following to your `packages.yml` file:

```yml
packages:
  - package: kayrnt/dbt_bigquery_monitoring
    version: 0.1.0
```

### Using the package

A lot of settings have default values that can be overriden using:

- dbt project variables (and therefore also by CLI variable override)
- environment variables

However some of them don't so you need to set all of them in your project variables or environment variables.

### Settings

Following settings are defined as `dbt_project_variable` (**Environment variable**).

#### Required settings

- `input_gcp_projects` (**DBT_BQ_MONITORING_GCP_PROJECTS**) : list of GCP projects to monitor

#### Optional settings

- `bq_region` (**DBT_BQ_MONITORING_REGION**) : region where the monitored projects are located (default: `us`)
- `use_flat_pricing` (**DBT_BQ_MONITORING_USE_FLAT_PRICING**) : whether to use flat pricing or not (default: `true`)
- `per_billed_tb_price` (**DBT_BQ_MONITORING_PER_BILLED_TB_PRICE**) : price per billed TB (default: `5`)
- `free_tb_per_month` (**DBT_BQ_MONITORING_FREE_TB_PER_MONTH**) : free TB per month (default: `1`)
- `hourly_slot_price` (**DBT_BQ_MONITORING_HOURLY_SLOT_PRICE**) : price per slot per hour (default: `0.04`)
- `active_logical_storage_gb_price` (**DBT_BQ_MONITORING_ACTIVE_LOGICAL_STORAGE_GB_PRICE**) : price per active logical storage GB (default: `0.02`)
- `long_term_logical_storage_gb_price` (**DBT_BQ_MONITORING_LONG_TERM_LOGICAL_STORAGE_GB_PRICE**) : price per long term logical storage GB (default: `0.01`)
- `active_physical_storage_gb_price` (**DBT_BQ_MONITORING_ACTIVE_PHYSICAL_STORAGE_GB_PRICE**) : price per active physical storage GB (default: `0.04`)
- `long_term_physical_storage_gb_price` (**DBT_BQ_MONITORING_LONG_TERM_PHYSICAL_STORAGE_GB_PRICE**) : price per long term physical storage GB (default: `0.02`)
- `free_storage_gb_per_month` (**DBT_BQ_MONITORING_FREE_STORAGE_GB_PER_MONTH**) : free storage GB per month (default: `10`)
- `lookback_window_days` (**DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS**) : number of days to look back for monitoring (default: `1`)
- `output_materialization` (**DBT_BQ_MONITORING_OUTPUT_MATERIALIZATION**) : materialization to use for the models (default: `table`)
- `output_limit_size` (**DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE**) : limit size to use for the models (default: `1000`)
