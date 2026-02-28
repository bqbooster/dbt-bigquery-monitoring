---
sidebar_position: 5.2
slug: /configuration/audit-logs
---

# GCP BigQuery audit logs

In this mode, the package monitors all the jobs that are written to a GCP
BigQuery audit logs table instead of using `INFORMATION_SCHEMA.JOBS`.

> **Next decision:** Compare options in the
> [decision tree](/configuration/decision-tree).

:::tip

To get the best out of this mode, you should enable the `should_combine_audit_logs_and_information_schema` setting to combine both sources.
More details on [the related page](/audit-logs-vs-information-schema).

:::

At the time of writing, there are 2 versions of the audit logs table. More details in [the repository from Google](https://github.com/GoogleCloudPlatform/bigquery-utils/tree/master/views/audit).

**dbt-bigquery-monitoring supports only the v2 version**
By default, the package reads from
`cloudaudit_googleapis_com_activity` if you do not override the table name.

To enable the "cloud audit logs mode", you'll need to define explicitly mandatory settings to set in the `dbt_project.yml` file:

```yml
vars:
  enable_gcp_bigquery_audit_logs: true
  gcp_bigquery_audit_logs_storage_project: 'my-gcp-project'
  gcp_bigquery_audit_logs_dataset: 'my_dataset'
  gcp_bigquery_audit_logs_table: 'cloudaudit_googleapis_com_activity'
  # should_combine_audit_logs_and_information_schema: true # Optional, default to false but you might want to combine both sources
```

[You might use environment variable as well](/configuration/package-settings).
