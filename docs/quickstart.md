---
sidebar_position: 1.5
slug: /quickstart
---

# Quickstart

Get `dbt-bigquery-monitoring` up and running in a few steps.

Before you start, check the [required rights](/required-rights) to make sure you have the right permissions.

## 1) Install the package

Add the package to your project by following the
[installation instructions](/installation#installing-the-package-to-your-dbt-project).

## 2) Set the minimum configuration

Set the output schema in `dbt_project.yml`.

```yml
models:
  dbt_bigquery_monitoring:
    +schema: "dbt_bigquery_monitoring"
```

If your datasets are not in the US region, also set `vars.bq_region` in
`dbt_project.yml` to your BigQuery region.

## 3) Install dependencies and run the package

Run dbt dependencies, then run the package models.

```bash
dbt deps
dbt run -s dbt_bigquery_monitoring
```

## 4) Check everything is working

Run the debug command to confirm your variables are set correctly.

1. Check your configuration:
   ```bash
   dbt run-operation debug_dbt_bigquery_monitoring_variables
   ```
2. Then head to the [configuration guide](/configuration) to enable additional data sources.
3. If something looks wrong, check [required rights](/required-rights).
