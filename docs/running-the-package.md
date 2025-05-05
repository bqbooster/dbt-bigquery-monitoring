---
sidebar_position: 6
slug: /running-the-package
---

# Running the package

## Region mode vs project mode

In region mode, the INFORMATION SCHEMA tables and wrapper models are ephemeral. So you may just use directly in your own models using `ref`.
**In region mode, you need to schedule something ONLY if you are using datamarts.**

In project mode, all the INFORMATION SCHEMA tables are copied to new consolidated tables and wrapper models are views. Then it requires to run recurringly both those base tables and the datamarts if you are planning to use them.

## Scheduling

The package is designed to be run as a daily or hourly job.
It leverages incremental modelisations to reduce the amount of data to process and to optimize the performance of the queries. Practically it won't reread data that has already been processed (and not needed anymore).

The granularity of the data partitioning is hourly so the most cost efficient way to process the data is run it every hour but you may run it more frequently if you need more "real-time" data.

### I am just using datamarts (Recommended)

If you plan to use the datamarts provided by the package, schedule running:
```
dbt run -s +tag:dbt-bigquery-monitoring-datamarts
```

### I am just using INFORMATION SCHEMA tables with project mode

If you are planning to use the consolidated INFORMATION SCHEMA tables, schedule running:

```
dbt run -s +tag:dbt-bigquery-monitoring-information-schema
```

### I'm going to use everything

If you are planning to use all tables, schedule running:

```
dbt run -s +tag:dbt-bigquery-monitoring
```

## Tags

The package provides the following tags that can be used to filter the models:

- all models: `+tag:dbt-bigquery-monitoring`
- information schema models: `+tag:dbt-bigquery-monitoring-information-schema`
- package datamarts: `+tag:dbt-bigquery-monitoring-datamarts`
- compute only datamarts: `+tag:dbt-bigquery-monitoring-compute`
- storage only datamarts: `+tag:dbt-bigquery-monitoring-storage`

As those models can rely on base models which means you have to run at least run base once.
To be sure, you just rely on the upstream dependency and run, for instance:

```
dbt run -s +tag:dbt-bigquery-monitoring-compute
```

Read more about the usage of provided models in [using the package](/using-the-package).
