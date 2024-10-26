# dbt-bigquery-monitoring

🚧 The package is still early stage and might vary a lot 🚧

dbt-bigquery-monitoring is a dbt package that provides models for monitoring BigQuery performance and costs.

## Getting started

*little tip: click on "Watch -> Custom -> Releases" to get an email on new versions with the changelog*

### dbt compatibility

The package is actively used with the latest dbt stable version which `1.8.2` at the time of writing.

### Granting rights

To use this package, you will need to grant permissions to the Service Account that dbt uses to connect to BigQuery.

There are various ways to add required permissions to leverage the extension.

#### "YOLO" mode

The simplest way is to give BQ admin access role:
- [BigQuery Admin](https://cloud.google.com/bigquery/docs/access-control#bigquery.admin) can do pretty much everything in BigQuery (so more than enough)

It's great for testing but not recommended for production where you'd rather follow the principle of least privilege.

#### Finer grain basic roles

Google provides some predefined roles that can be used to grant the necessary permissions to the service account that dbt uses to connect to BigQuery.

Here's the list of predefined roles that can be combined to cover the extension needs:

- [BigQuery Data Editor](https://cloud.google.com/bigquery/docs/access-control#bigquery.dataEditor) to list and modify datasets/tables
- [BigQuery User](https://cloud.google.com/bigquery/docs/access-control#bigquery.user) to run queries
- [BigQuery Resource Viewer](https://cloud.google.com/bigquery/docs/access-control#bigquery.resourceViewer) to access some metadata tables

#### Custom roles

<details>
<summary>
if you prefer to use custom roles, you can use the following permissions.
</summary >

This list might not be exhaustive and you might need to add more permissions depending on your use case but it should be a good start:

- __bigquery.jobs.create__ - To Create BigQuery request
- __bigquery.tables.get__ - To access BigQuery tables data
- __bigquery.tables.list__ - To access BigQuery tables data
- __bigquery.jobs.listAll__ - To access BigQuery jobs data

   - At the organization or project level, depending on desired scope
   - Note that JOBS_BY_ORGANIZATION is only available to users with defined Google Cloud organizations. More information on permissions and access control in BigQuery can be found [here](https://cloud.google.com/bigquery/docs/access-control).

- __bigquery.reservations.list__ - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- __bigquery.capacityCommitments.list__ - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- __bigquery.reservationAssignments.list__ - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)

</details>

### Installing the package to your dbt project

Add the following to your `packages.yml` file:

```yml {"id":"01J6QQ78T6KQCXF8VPNH8BXBYM"}
packages:
  - package: bqbooster/dbt_bigquery_monitoring
    version: 0.10.2
```

### Set up an output dataset

In your dbt_project.yml file, add the following configuration:

```yml {"id":"01J6QQ78T7AR9FAHKAFYQCJZ41"}
models:
  ## dbt-bigquery-models models will be created in the schema '<your_schema>_dbt_bigquery_monitoring' (or anything related if you override output schema system through a macro)
  dbt_bigquery_monitoring:
    +schema: "dbt_bigquery_monitoring"
```

### Configure the package

Settings have default values that can be overriden using:

- dbt project variables (and therefore also by CLI variable override)
- environment variables

Please note that the default region is `us` and there's no way, at the time of writing, to query cross region tables but you might run that project in each region you want to monitor and [then replicate the tables to a central region](https://cloud.google.com/bigquery/docs/data-replication) to build an aggregated view.

To know which region is related to a job, in the BQ UI, use the `Job history` (bottom panel), take a job and look at `Location` field when clicking on a job. You can also access the region of a dataset/table by opening the details panel of it and check the `Data location` field.

#### Modes

##### Region mode (default)

In this mode, the package will monitor all the GCP projects in the region specified in the `dbt_project.yml` file.

```yml {"id":"01J6QQ78T7AR9FAHKAG0C6D6SZ"}
vars:
  # dbt bigquery monitoring vars
  bq_region: 'us'
```

**Requirements**

- Execution project needs to be the same as the storage project else you'll need to use the second mode.
- If you have multiple GCP Projects in the same region, you should use the "project mode" (with `input_gcp_projects` setting to specify them) as else you will run into errors such as: `Within a standard SQL view, references to tables/views require explicit project IDs unless the entity is created in the same project that is issuing the query, but these references are not project-qualified: "region-us.INFORMATION_SCHEMA.JOBS"`.

##### Project mode

To enable the "project mode", you'll need to define explicitly one mandatory setting to set in the `dbt_project.yml` file:

```yml {"id":"01J6QQ78T7AR9FAHKAG3ASVQHP"}
vars:
  # dbt bigquery monitoring vars
  input_gcp_projects: [ 'my-gcp-project', 'my-gcp-project-2' ]
```

##### GCP Billing export

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

#### Customizing the package configuration

<details>
<summary>
Settings details
</summary>

Following settings are defined with following template: `dbt_project_variable` (__Environment variable__) : description (default if any).

#### Optional settings

##### Environment

- `input_gcp_projects` (__DBT_BQ_MONITORING_GCP_PROJECTS__) : list of GCP projects to monitor (default: `[]`)
- `bq_region` (__DBT_BQ_MONITORING_REGION__) : region where the monitored projects are located (default: `us`)

##### Pricing

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

###### Package

- `lookback_window_days` (__DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS__) : number of days to look back for monitoring (default: `7`)
- `output_limit_size` (__DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE__) : limit size to use for the models (default: `1000`)
- `output_partition_expiration_days` (__DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE__) : default table expiration in days for incremental models (default: `365` days)
- `use_copy_partitions` (__DBT_BQ_MONITORING_USE_COPY_PARTITIONS__) : whether to use copy partitions or not (default: `true`)

###### GCP Billing export
- `enable_gcp_billing_export` (__DBT_BQ_MONITORING_ENABLE_GCP_BILLING_EXPORT__) : toggle to enable GCP billing export monitoring (default: `false`)
- `gcp_billing_export_storage_project` (__DBT_BQ_MONITORING_GCP_BILLING_EXPORT_STORAGE_PROJECT__) : the GCP project where billing export data is stored (default: `'placeholder'` if `enable_gcp_billing_export` is `true`; otherwise `None`)
- `gcp_billing_export_dataset` (__DBT_BQ_MONITORING_GCP_BILLING_EXPORT_DATASET__) : the dataset for GCP billing export data (default: `'placeholder'` if `enable_gcp_billing_export` is `true`; otherwise `None`)
- `gcp_billing_export_table` (__DBT_BQ_MONITORING_GCP_BILLING_EXPORT_TABLE__) : the table for GCP billing export data (default: `'placeholder'` if `enable_gcp_billing_export` is `true`; otherwise `None`)


</details>

#### Add metadata to queries (Recommended but optional)

To enhance your query metadata with dbt model information, the package provides a dedicated macro that leverage "dbt query comments" (the header set at the top of each query)
To configure the query comments, add the following config to `dbt_project.yml`.

```yaml {"id":"01J6QQ78T7AR9FAHKAG3R5WP1F"}
query-comment:
  comment: '{{ dbt_bigquery_monitoring.get_query_comment(node) }}'
```

### Running the package

The package is designed to be run as a daily or hourly job.
To do so, you can use the following dbt command:

```bash {"id":"01J6QQ78T7AR9FAHKAG7CQMP48"}
dbt run -s tag:dbt-bigquery-monitoring
```

#### Tags

The package provides the following tags that can be used to filter the models:

- compute: `tag:dbt-bigquery-monitoring-compute`
- storage: `tag:dbt-bigquery-monitoring-storage`

As those models can rely on base models which means you have to run at least run base once.
To be sure, you just rely on the upstream dependency and run, for instance:

```bash {"id":"01J6QQ78T7AR9FAHKAG8522SEV"}
dbt run -s +tag:dbt-bigquery-monitoring-compute
```

### Using the package

#### Google INFORMATION_SCHEMA tables

Following models are available to query the INFORMATION_SCHEMA tables. They are materialized as `ephemeral` in dbt so it acts as a "source" but let you access multiple multiple project based tables using a single `ref`.

##### Example

You can use those models such as:

```sql {"id":"01J6QQ78T7AR9FAHKAGA263BMF"}
SELECT query FROM {{ ref('information_schema_jobs') }}
```

<details>
<summary>
Here's the list (**don't forget to prefix the following list by `information_schema_` in your `ref` call**).
</summary>

- access_control

   - object_privileges

- bi_engine

   - bi_capacities
   - bi_capacity_changes

- configuration

   - effective_project_options
   - organization_options
   - organization_options_changes
   - project_options
   - project_options_changes

- datasets

   - links
   - schemata
   - schemata_options
   - schemata_replicas
   - shared_dataset_usage

- jobs

   - jobs
   - jobs_by_folder
   - jobs_by_organization
   - jobs_by_project
   - jobs_by_user

- jobs_timeline

   - jobs_timeline
   - jobs_timeline_by_folder
   - jobs_timeline_by_organization
   - jobs_timeline_by_user

- recommendations_and_insights

   - insights
   - recommendations_by_organization
   - recommendations

- reservations

   - assignment_changes
   - assignments
   - capacity_commitment_changes
   - capacity_commitments
   - reservation_changes
   - reservations
   - reservations_timeline

- routines

   - parameters
   - routine_options
   - routines

- search_indexes

   - search_index_columns
   - search_indexes

- sessions

   - sessions
   - sessions_by_project
   - sessions_by_user

- streaming

   - streaming_timeline
   - streaming_timeline_by_folder
   - streaming_timeline_by_organization

- tables

   - column_field_paths
   - columns
   - constraint_column_usage
   - key_column_usage
   - partitions
   - table_constraints
   - table_options
   - table_snapshots
   - table_storage
   - table_storage_by_organization
   - table_storage_usage_timeline
   - table_storage_usage_timeline_by_organization
   - tables

- vector_indexes

   - vector_index_columns
   - vector_index_options
   - vector_indexes

- views

   - materialized_views
   - views

- write_api

   - write_api_timeline
   - write_api_timeline_by_folder
   - write_api_timeline_by_organization


- gcp_billing_export

   - gcp_billing_export_resource_v1

#### Models

The package provides the following datamarts that can be easily used to build monitoring charts and dashboards:

- global

   - `daily_spend`
   - `dbt_bigquery_monitoring_options`

- compute

   - `compute_billing_per_hour`
   - `compute_cost_per_hour`
   - `most_expensive_jobs`
   - `most_expensive_models`
   - `most_expensive_users`
   - `most_repeated_jobs`
   - `most_repeated_models`
   - `slowest_jobs`

- storage

   - `dataset_with_better_pricing_on_logical_billing_model`
   - `dataset_with_better_pricing_on_physical_billing_model`
   - `dataset_with_cost`
   - `most_expensive_tables`
   - `partitions_monitoring`
   - `read_heavy_tables`
   - `storage_billing_per_hour`
   - `table_with_better_pricing_on_logical_billing_model`
   - `table_with_better_pricing_on_physical_billing_model`
   - `unused_tables`

</details>

## Contributing

If you feel like contribute, don't hesitate to open an issue and submit a PR.
For more details, please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file.
