---
sidebar_position: 4
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

To enable the "project mode", you'll need to define explicitly one mandatory setting to set in the `dbt_project.yml` file:

```yml
vars:
  # dbt bigquery monitoring vars
  input_gcp_projects: [ 'my-gcp-project', 'my-gcp-project-2' ]
```

## Add metadata to queries (Recommended but optional)

To enhance your query metadata with dbt model information, the package provides a dedicated macro that leverage "dbt query comments" (the header set at the top of each query)
To configure the query comments, add the following config to `dbt_project.yml`.

```yaml
query-comment:
  comment: '{{ dbt_bigquery_monitoring.get_query_comment(node) }}'
  job-label: True # Use query comment JSON as job labels
```

