---
sidebar_position: 6
slug: /running-the-package
---

# Running the package

The package is designed to be run as a daily or hourly job.
To do so, you can use the following dbt command:

```
dbt run -s tag:dbt-bigquery-monitoring
```

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
