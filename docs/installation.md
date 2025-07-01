---
sidebar_position: 4
slug: /installation
---

# Installation

## Installing the package to your dbt project

Add the following to your `packages.yml` file:

```yml
packages:
  - package: bqbooster/dbt_bigquery_monitoring
    version: 0.20.3
```

## Set up an output dataset

In your dbt_project.yml file, add the following configuration:

```yml
models:
  ## dbt-bigquery-models models will be created in the schema '<your_schema>_dbt_bigquery_monitoring' (or anything related if you override output schema system through a macro)
  dbt_bigquery_monitoring:
    +schema: "dbt_bigquery_monitoring"
```
