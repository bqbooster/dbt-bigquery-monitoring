---
sidebar_position: 5
slug: /configuration
---

# Configuration

Settings have default values that can be overriden using:

- dbt project variables (and therefore also by CLI variable override)
- environment variables

Please note that the default region is `us` and there's no way, at the time of writing, to query cross region tables but you might run that project in each region you want to monitor and [then replicate the tables to a central region](https://cloud.google.com/bigquery/docs/data-replication) to build an aggregated view.

To know which region is related to a job, in the BQ UI, use the `Job history` (bottom panel), take a job and look at `Location` field when clicking on a job. You can also access the region of a dataset/table by opening the details panel of it and check the `Data location` field.

:::tip

To get the best out of this package, you should probably configure all data sources and settings:
- Choose the [Baseline mode](#modes) that fits your GCP setup
- [Add metadata to queries](#add-metadata-to-queries-recommended-but-optional)
- [GCP BigQuery Audit logs](/configuration/audit-logs)
- [GCP Billing export](/configuration/gcp-billing)
- [Settings](/configuration/package-settings) (especially the pricing ones)

:::


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

Project mode is useful when you have multiple GCP projects or you want to store the dbt-bigquery-monitoring models in a project different from the one used for execution.
To enable the "project mode", you'll need to define explicitly one mandatory setting to set in the `dbt_project.yml` file:

```yml
vars:
  # dbt bigquery monitoring vars
  input_gcp_projects: [ 'my-gcp-project', 'my-gcp-project-2' ]
```

#### Supported Input Formats

The `input_gcp_projects` setting accepts multiple input formats for maximum flexibility:

**1. dbt project variables (dbt_project.yml):**
```yml
vars:
  input_gcp_projects: "single-project"                    # Single project as string
  input_gcp_projects: ["project1", "project2"]            # Multiple projects as array
```

**2. CLI variables:**
```bash
dbt run --vars '{"input_gcp_projects": "test"}'                   # Single project
dbt run --vars '{"input_gcp_projects": ["test1", "test2"]}'       # Multiple projects
```

**3. Environment variables:**
```bash
# Single project
export DBT_BQ_MONITORING_GCP_PROJECTS="single-project"

# Multiple projects with quotes
export DBT_BQ_MONITORING_GCP_PROJECTS='["project1","project2"]'

# Multiple projects without quotes (also supported)
export DBT_BQ_MONITORING_GCP_PROJECTS='[project1,project2]'

# Single project in array format
export DBT_BQ_MONITORING_GCP_PROJECTS='["project1"]'
export DBT_BQ_MONITORING_GCP_PROJECTS='[project1]'

# Empty array
export DBT_BQ_MONITORING_GCP_PROJECTS='[]'
```

All input formats are automatically normalized to an array of project strings internally, so you can use whichever format is most convenient for your setup.

:::warning

When using the "project mode", the package will create intermediate tables to avoid issues from BigQuery when too many projects are used.
That process is done only on tables that are project related. The package leverages a custom materialiation (`project_by_project_table`) designed specifically for that need that can found in the `macros` folder.

:::

## Add metadata to queries (Recommended but optional)

To enhance your query metadata with dbt model information, the package provides a dedicated macro that leverage "dbt query comments" (the header set at the top of each query)
To configure the query comments, add the following config to `dbt_project.yml`.

```yaml
query-comment:
  comment: '{{ dbt_bigquery_monitoring.get_query_comment(node) }}'
  job-label: true # Use query comment JSON as job labels
```

To get more details about query comments, please refer to the [dbt documentation](https://docs.getdbt.com/reference/project-configs/query-comment).

## Troubleshooting Configuration

If you're having trouble with your configuration or want to verify that your environment variables and dbt variables are being resolved correctly, you can use the built-in debug macro to log all configuration values.

### Example Usage

Run this command to see the configuration debug information:

```bash
dbt run-operation debug_dbt_bigquery_monitoring_variables
```

### Variable priority

The package will prioritize the configuration variables in the following order:

1. Environment variables
2. dbt variables
3. variables in the `dbt_project.yml` file
4. default values
