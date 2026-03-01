---
sidebar_position: 1.5
slug: /quickstart
---

# Quickstart

Get `dbt-bigquery-monitoring` up and running in under 5 minutes.

Before you start, check the [required rights](/required-rights) to make sure your service account has the necessary IAM roles.

---

## 1) Install the package

Add to `packages.yml` (check [dbt Hub](https://hub.getdbt.com/bqbooster/dbt_bigquery_monitoring/latest/) for the latest version):

```yml
# packages.yml
packages:
  - package: bqbooster/dbt_bigquery_monitoring
    version: [">=0.24.0", "<1.0.0"]
```

```bash
dbt deps
```

## 2) Set the minimum configuration

In `dbt_project.yml`, set the output schema and your BigQuery region:

```yml
# dbt_project.yml
models:
  dbt_bigquery_monitoring:
    +schema: "dbt_bigquery_monitoring"   # tables land in <target_schema>_dbt_bigquery_monitoring

vars:
  bq_region: 'us'       # Change to 'EU', 'europe-west1', etc. if needed
```

:::tip

Not sure of your region? In the BigQuery UI, open **Job history** (bottom panel),
click any job, and check the **Location** field.

:::

## 3) Run the package

```bash
dbt run -s dbt_bigquery_monitoring
```

## 4) Verify the setup

Run the debug operation to confirm all variables are resolved as expected:

```bash
dbt run-operation debug_dbt_bigquery_monitoring_variables
```

Then try a quick sanity-check query:

```sql
-- Most expensive queries in the last 24 hours
SELECT
  user_email,
  LEFT(query, 80) AS query_preview,
  ROUND(query_cost, 4) AS cost_usd
FROM {{ ref('most_expensive_jobs') }}
WHERE DATE(hour) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
ORDER BY query_cost DESC
LIMIT 10
```

## 5) What's next?

| Goal | Guide |
|---|---|
| Monitor multiple GCP projects | [Project mode](/configuration#project-mode) |
| Get exact dollar costs | [GCP Billing export](/configuration/gcp-billing) |
| Query history beyond 6 months | [Audit logs](/configuration/audit-logs) |
| Trace costs to dbt models | [Add metadata to queries](/configuration#add-metadata-to-queries-recommended) |
| See all available variables | [Package settings](/configuration/package-settings) |
| Schedule regular runs | [Running the package](/running-the-package) |
