# dbt-bigquery-monitoring

🚧 The package is still early stage and might vary a lot 🚧

dbt-bigquery-monitoring is a dbt package that provides models for monitoring BigQuery performance and costs.

## Get started

### Granting rights

To use this package, you will need to grant permissions to the Service Account that dbt uses to connect to BigQuery.

The required permissions (listed above) are available to:

- [`BigQuery Resource Admin`](https://cloud.google.com/bigquery/docs/access-control#bigquery.resourceAdmin)
- [`BigQuery Admin`](https://cloud.google.com/bigquery/docs/access-control#bigquery.admin) roles but feel free to create a custom role.

<details>
<summary>
if you prefer to use custom roles, you can use the following permissions.
</summary>

- **bigquery.tables.get** - To [access BigQuery tables data](https://cloud.google.com/bigquery/docs/information-schema-table-storage#required_roles)
- **bigquery.tables.list** - To [access BigQuery tables data](https://cloud.google.com/bigquery/docs/information-schema-table-storage#required_roles)
- **bigquery.jobs.listAll**
  - At the organization or project level, depending on desired scope
  - Note that JOBS_BY_ORGANIZATION is only available to users with defined Google Cloud organizations. More information on permissions and access control in BigQuery can be found [here](https://cloud.google.com/bigquery/docs/access-control).
- **bigquery.reservations.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- **bigquery.capacityCommitments.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- **bigquery.reservationAssignments.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)

</details>

### Installing the package to your dbt project

Add the following to your `packages.yml` file:

```yml
packages:
  - package: bqbooster/dbt_bigquery_monitoring
    version: 0.5.0
```

### Configure the package

Settings have default values that can be overriden using:

- dbt project variables (and therefore also by CLI variable override)
- environment variables

Please note that the default region is `us` and there's no way, at the time of writing, to query cross region tables but you might run that project in each region you want to monitor and [then replicate the tables to a central region](https://cloud.google.com/bigquery/docs/data-replication) to build an aggregated view.

To know which region is related to a job, in the BQ UI, use the `Job history` (bottom panel), take a job and look at `Location` field when clicking on a job. You can also access the region of a dataset/table by opening the details panel of it and check the `Data location` field.

#### Modes

###### Region mode (default)
In this mode, the package will monitor all the GCP projects in the region specified in the `dbt_project.yml` file.

```yml
vars:
  # dbt bigquery monitoring vars
  bq_region: 'us'
```

**Requirements**
- Execution project needs to be the same as the storage project else you'll need to use the second mode.
- If you have multiple GCP Projects in the same region, you should use the "project mode" (with `input_gcp_projects` setting to specify them) as else you will run into errors such as: `Within a standard SQL view, references to tables/views require explicit project IDs unless the entity is created in the same project that is issuing the query, but these references are not project-qualified: "region-us.INFORMATION_SCHEMA.JOBS"`.

###### Project mode

To enable the "project mode", you'll need to define explicitly one mandatory setting to set in the `dbt_project.yml` file:

```yml
vars:
  # dbt bigquery monitoring vars
  input_gcp_projects: [ 'my-gcp-project', 'my-gcp-project-2' ]
```

<details>
<summary>
Settings details
</summary>

Following settings are defined as `dbt_project_variable` (**Environment variable**).

#### Optional settings

##### Environment
- `input_gcp_projects` (**DBT_BQ_MONITORING_GCP_PROJECTS**) : list of GCP projects to monitor (default: `[]`)
- `bq_region` (**DBT_BQ_MONITORING_REGION**) : region where the monitored projects are located (default: `us`)

##### Pricing
- `use_flat_pricing` (**DBT_BQ_MONITORING_USE_FLAT_PRICING**) : whether to use flat pricing or not (default: `true`)
- `per_billed_tb_price` (**DBT_BQ_MONITORING_PER_BILLED_TB_PRICE**) : price per billed TB (default: `6,25`)
- `free_tb_per_month` (**DBT_BQ_MONITORING_FREE_TB_PER_MONTH**) : free TB per month (default: `1`)
- `hourly_slot_price` (**DBT_BQ_MONITORING_HOURLY_SLOT_PRICE**) : price per slot per hour (default: `0.04`)
- `active_logical_storage_gb_price` (**DBT_BQ_MONITORING_ACTIVE_LOGICAL_STORAGE_GB_PRICE**) : price per active logical storage GB (default: `0.02`)
- `long_term_logical_storage_gb_price` (**DBT_BQ_MONITORING_LONG_TERM_LOGICAL_STORAGE_GB_PRICE**) : price per long term logical storage GB (default: `0.01`)
- `active_physical_storage_gb_price` (**DBT_BQ_MONITORING_ACTIVE_PHYSICAL_STORAGE_GB_PRICE**) : price per active physical storage GB (default: `0.04`)
- `long_term_physical_storage_gb_price` (**DBT_BQ_MONITORING_LONG_TERM_PHYSICAL_STORAGE_GB_PRICE**) : price per long term physical storage GB (default: `0.02`)
- `free_storage_gb_per_month` (**DBT_BQ_MONITORING_FREE_STORAGE_GB_PER_MONTH**) : free storage GB per month (default: `10`)

###### Package
- `lookback_window_days` (**DBT_BQ_MONITORING_LOOKBACK_WINDOW_DAYS**) : number of days to look back for monitoring (default: `7`)
- `output_limit_size` (**DBT_BQ_MONITORING_OUTPUT_LIMIT_SIZE**) : limit size to use for the models (default: `1000`)

</details>

#### Add metadata to queries (Recommanded but optional)

To enhance your query metadata with dbt model information, the package provides a dedicated macro that leverage "dbt query comments" (the header set at the top of each query)
To configure the query comments, add the following config to `dbt_project.yml`.

```yaml
query-comment:
  comment: '{{ dbt_bigquery_monitoring.get_query_comment(node) }}'
```

### Running the package

The package is designed to be run as a daily or hourly job.
To do so, you can use the following dbt command:

```bash
dbt run -s tag:dbt-bigquery-monitoring
```

#### Tags

The package provides the following tags that can be used to filter the models:
- compute: `tag:dbt-bigquery-monitoring-compute`
- storage: `tag:dbt-bigquery-monitoring-storage`

As those models can rely on base models which means you have to run at least run base once.
To be sure, you just rely on the upstream dependency and run, for instance:
```bash
dbt run -s +tag:dbt-bigquery-monitoring-compute
```

### Using the package

#### Google INFORMATION_SCHEMA tables

Following models are available to query the INFORMATION_SCHEMA tables. They are materialized as `ephemeral` in dbt so it acts as a "source" but let you access multiple multiple project based tables using a single `ref`.

##### Example
You can use those models such as:
```sql
SELECT query FROM {{ ref('information_schema_jobs') }}
```

##### Tables

Here's the list (**don't forget to prefix the following list by `information_schema_` in your `ref` call**):
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

#### Models

The package provides the following datamarts that can be easily used to build monitoring charts and dashboards:

- global
  - `daily_spend`

- compute
  - `compute_cost_per_hour`
  - `most_expensive_jobs`
  - `most_expensive_users`
  - `most_repeated_jobs`
  - `slowest_jobs`

- storage
  - `most_expensive_tables`
  - `read_heavy_tables`
  - `unused_tables`

## Contributing

If you feel like contribute, don't hesitate to open an issue and submit a PR.

### Setup a profile

To run the package in development mode (ie from that repository instead of through an installed package), you will need to setup a profile that will be used to connect to BigQuery.

The profile used is for the project `dbt_bigquery_monitoring` and can be configured as follow for a production account using a service account keyfile:

```yaml
dbt_bigquery_monitoring:
  outputs:
    default:
      type: bigquery

      ## Service account auth ##
      method: service-account
      keyfile: [full path to your keyfile]

      project: [project id] # storage project
      execution_project: [execution project id] # execution project
      dataset: [dataset name] # dbt_bigquery_monitoring dataset, you may just use dbt_bigquery_monitoring
      threads: 4
      location: [dataset location]
      priority: interactive

      timeout_seconds: 1000000
```

if you're running locally to try the package you can swap the `method` to `method: oauth` (and remove the `keyfile` line).
