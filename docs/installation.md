---
sidebar_position: 4
slug: /installation
---

# Installation

New to the package? Follow the [Quickstart](/quickstart) to get up and running in minutes.

## Step 1 — Add the package to `packages.yml`

Add the following to your project's `packages.yml` file and run `dbt deps`:

```yml
# packages.yml
packages:
  - package: bqbooster/dbt_bigquery_monitoring
    version: [">=0.24.0", "<1.0.0"]   # pin to a compatible range
```

Check [dbt Hub](https://hub.getdbt.com/bqbooster/dbt_bigquery_monitoring/latest/) for the latest version.

Then install dependencies:

```bash
dbt deps
```

## Step 2 — Configure the output schema

Add the following to your `dbt_project.yml` to set where the monitoring tables will be written.
dbt appends the schema name to your target schema, so this creates `<target_schema>_dbt_bigquery_monitoring`.

```yml
# dbt_project.yml
models:
  # dbt-bigquery-monitoring models will be created in '<your_schema>_dbt_bigquery_monitoring'
  dbt_bigquery_monitoring:
    +schema: "dbt_bigquery_monitoring"
```

## Step 3 — Set minimum variables

At minimum, set your BigQuery region if it is not `us`:

```yml
# dbt_project.yml
vars:
  bq_region: 'us'    # default — change to 'EU', 'europe-west1', etc. if needed
```

Then head to the [configuration guide](/configuration) to enable additional data sources and fine-tune settings.

## Requirements

- **dbt Core** >= 1.3.0 or **dbt Fusion** >= 2.0.0-beta
- BigQuery adapter (`dbt-bigquery`)
- The service account used by dbt must have the [required IAM permissions](/required-rights)
