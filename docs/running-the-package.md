---
sidebar_position: 6
slug: /running-the-package
---

# Running the package

Before you schedule jobs, complete the
[setup wizard](/configuration/setup-wizard) so scheduling follows your
configuration choices.

## Region mode vs project mode

In region mode, the INFORMATION SCHEMA tables and wrapper models are ephemeral,
so you can use them directly in your own models with `ref`.
**In region mode, you need to schedule something ONLY if you are using datamarts.**

In project mode, all INFORMATION SCHEMA tables are copied into new consolidated
tables and wrapper models are views. You must run both those base tables and
the datamarts regularly if you plan to use them.

## Scheduling

The package is designed to be run as a daily or hourly job.
It uses incremental models to reduce the amount of data to process and optimize
query performance. In practice, it does not reread data that has already been
processed and is no longer needed.

The data partitioning granularity is hourly, so the most cost-efficient way to
process the data is to run it every hour, but you can run it more frequently if
you need more "real-time" data.

### I am just using datamarts (Recommended)

If you plan to use the datamarts provided by the package, schedule running:

```bash
dbt run -s +tag:dbt-bigquery-monitoring-datamarts
```

### I am just using INFORMATION SCHEMA tables with project mode

If you are planning to use the consolidated INFORMATION SCHEMA tables, schedule running:

```bash
dbt run -s +tag:dbt-bigquery-monitoring-information-schema
```

### I'm going to use everything

If you are planning to use all tables, schedule running:

```bash
dbt run -s +tag:dbt-bigquery-monitoring
```

## Tags

The package provides the following tags that can be used to filter the models:

- all models: `+tag:dbt-bigquery-monitoring`
- information schema models: `+tag:dbt-bigquery-monitoring-information-schema`
- package datamarts: `+tag:dbt-bigquery-monitoring-datamarts`
- compute only datamarts: `+tag:dbt-bigquery-monitoring-compute`
- storage only datamarts: `+tag:dbt-bigquery-monitoring-storage`

Some models rely on base models, which means you must run the base models at
least once. To ensure this, rely on upstream dependencies and run, for
instance:

```bash
dbt run -s +tag:dbt-bigquery-monitoring-compute
```

:::tip

The plugin does not behave well in CI environments because it requires
extensive rights to read the INFORMATION SCHEMA tables. I usually recommend
excluding the package from CI runs and running it only in production
environments. To do so, use the `--exclude` option to exclude package models
from CI runs:

```bash
dbt run --exclude tag:dbt-bigquery-monitoring
```

:::

Read more about the usage of provided models in [using the package](/using-the-package).
