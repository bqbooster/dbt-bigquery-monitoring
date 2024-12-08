---
sidebar_position: 5
slug: /audit-logs-vs-information-schema
---

# Audit logs vs Information schema

There are two ways to monitor BigQuery jobs:
- Using the BigQuery audit logs
- Using the `INFORMATION_SCHEMA.JOBS` table

## How to choose

Each of the solution has its advantages and disadvantages. Here is a comparison table to help you choose the right one for your use case:

| Feature | Audit logs | INFORMATION_SCHEMA |
|---------|------------|--------------------|
| Max retention | User defined | 6 months |
| Detailed User information | ✅ | ❌ |
| BI Engine | ❌ | ✅ |
| Insights | ❌ | ✅ |

At some point, a mode to combine both solutions could be implemented.

## Audit logs

[Audit logs were introduced in 2021](https://cloud.google.com/blog/products/data-analytics/bigquery-audit-logs-pipelines-analysis) as an alternative to the `INFORMATION_SCHEMA.JOBS` table. They provide more detailed information about the user who ran the query and can have more historical data.

## Information schema

The `INFORMATION_SCHEMA.JOBS` table is a system table that contains information about the jobs that have been run in BigQuery. It provides a lot of information about the job such BI engine and insights.
