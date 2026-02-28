---
sidebar_position: 5.1
slug: /audit-logs-vs-information-schema
---

# Audit logs vs Information schema

There are two ways to monitor BigQuery jobs:

Not sure which to choose? See the [comparison guide](/audit-logs-vs-information-schema) for a full breakdown.

- Using the BigQuery audit logs
- Using the `INFORMATION_SCHEMA.JOBS` table

dbt-bigquery-monitoring supports both methods and goes further by providing a unified way to monitor both by offering a configuration that will combine the two sources.
See `should_combine_audit_logs_and_information_schema` in the [configuration](/configuration) if you want to combine the two sources.

## What's in there?

Each solution has its advantages and disadvantages. Here is a comparison table
to help you choose the right one for your use case:

| Feature | Audit logs | INFORMATION_SCHEMA |
|---------|------------|--------------------|
| Max retention | User defined | 6 months |
| Detailed User information | ✅ | ❌ |
| BI Engine | ❌ | ✅ |
| Jobs insights | ❌ | ✅ |

## Audit logs

[Audit logs were introduced in 2021](https://cloud.google.com/blog/products/data-analytics/bigquery-audit-logs-pipelines-analysis) as an alternative to the `INFORMATION_SCHEMA.JOBS` table. They provide more detailed information about the user who ran the query and can have more historical data.

## Information schema

The `INFORMATION_SCHEMA.JOBS` table is a system table that contains
information about the jobs that have been run in BigQuery. It provides a lot
of information about the job, such as BI Engine and insights.
