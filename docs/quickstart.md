---
sidebar_position: 1.5
slug: /quickstart
---

# Quickstart

Use this page as the canonical first-run path for
`dbt-bigquery-monitoring`.

## 1) Install the package

Add the package to your `packages.yml` file.

```yml
packages:
  - package: bqbooster/dbt_bigquery_monitoring
    version: 0.24.1
```

## 2) Set the minimum configuration

Set the output schema in `dbt_project.yml`.

```yml
models:
  dbt_bigquery_monitoring:
    +schema: "dbt_bigquery_monitoring"
```

## 3) Install dependencies and run the package

Run dbt dependencies, then run the package models.

```bash
dbt deps
dbt run -s dbt_bigquery_monitoring
```

## 4) Validate and choose your configuration path

Validate results, then choose the right configuration path for your setup.

1. Run configuration troubleshooting:
   ```bash
   dbt run-operation debug_dbt_bigquery_monitoring_variables
   ```
2. Follow the [configuration decision flow](/audit-logs-vs-information-schema).
3. If needed, use [configuration troubleshooting](/configuration#troubleshooting-configuration).
