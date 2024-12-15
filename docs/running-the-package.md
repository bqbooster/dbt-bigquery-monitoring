---
sidebar_position: 6
slug: /running-the-package
---

# Running the package

The package is designed to be run as a daily or hourly job.
It leverages incremental modelisations to reduce the amount of data to process and to optimize the performance of the queries. Practically it won't reread data that has already been processed (and not needed anymore).

If you plan to run all models, the simplest way to run the job is to run the following dbt command:

```
dbt run -s tag:dbt-bigquery-monitoring
```

The granularity of the data partitioning is hourly so the most cost efficient way to process the data is run it every hour but you may run it more frequently if you need more "real-time" data.

## Tags

The package provides the following tags that can be used to filter the models:

- compute: `tag:dbt-bigquery-monitoring-compute`
- storage: `tag:dbt-bigquery-monitoring-storage`

As those models can rely on base models which means you have to run at least run base once.
To be sure, you just rely on the upstream dependency and run, for instance:

```
dbt run -s +tag:dbt-bigquery-monitoring-compute
```

Read more about the usage of provided models in [using the package](/using-the-package).
