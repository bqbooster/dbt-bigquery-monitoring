---
sidebar_position: 8
slug: /datamarts
---

# Monitoring Datamarts

The package provides a set of **Datamarts**—high-level, business-ready tables—that make it easy to analyze your BigQuery usage without wrestling with raw logs.

These models are designed to be:
*   **Directly queried** for ad-hoc analysis.
*   **Connected to BI tools** (Looker, Tableau, Superset) for dashboards.
*   **Used for alerting** (e.g., "Alert me if daily spend > $500").

---

## 🌍 Global Monitoring

### `daily_spend`

This is your top-level executive summary. It aggregates all costs (Compute + Storage) by day.

**Key Columns:**
*   `day`: The date of the cost.
*   `cost_category`: 'compute' or 'storage'.
*   `cost`: The amount in your billing currency.

**📝 Example Query: Visualize Daily Trend**

```sql
SELECT
  day,
  cost_category,
  sum(cost) as total_cost
FROM {{ ref('daily_spend') }}
WHERE day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2
ORDER BY 1 DESC
```

---

## ⚡ Compute Monitoring

These models help you understand *who* is running queries and *how much* they cost.

### `most_expensive_jobs`

Identifies individual queries that are driving up your bill. Great for spotting inefficient queries or "outlier" events relative to your normal workload.

**Key Columns:**
*   `job_id`: Unique BigQuery job ID.
*   `user_email`: Who ran it.
*   `query`: The SQL text (truncated or full, depending on configuration).
*   `query_cost`: Cost of this single execution.
*   `total_slot_ms`: Measure of unexpected complexity.

**📝 Example Query: "Who spent more than $10 on a single query yesterday?"**

```sql
SELECT
  user_email,
  job_id,
  query_cost,
  LEFT(query, 100) as query_preview
FROM {{ ref('most_expensive_jobs') }}
WHERE query_cost > 10
  AND date(hour) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
ORDER BY query_cost DESC
```

### `most_expensive_users`

Group costs by user or service account. Useful for chargebacks or identifying teams that need optimization training.

**📝 Example Query: Top 5 Spenders this Month**

```sql
SELECT
  user_email,
  round(sum(cost), 2) as total_spend
FROM {{ ref('most_expensive_users') }}
WHERE date(hour) >= DATE_TRUNC(CURRENT_DATE(), MONTH)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5
```

---

## 💾 Storage Monitoring

Storage costs are often "silent killers" because they accumulate over time. These models help you prune the dead weight.

### `most_expensive_tables`

Lists your largest tables and their associated costs. It also calculates forecasted monthly costs.

**Key Columns:**
*   `project_id`, `dataset_id`, `table_id`: Full path to the table.
*   `total_logical_bytes` / `total_physical_bytes`: Size metrics.
*   `cost_monthly_forecast`: Estimated monthly bill for this table.
*   `storage_billing_model`: whether you are billed for Logical or Physical bytes.

**📝 Example Query: "What are my top 10 most expensive tables?"**

```sql
SELECT
  project_id,
  dataset_id,
  table_id,
  round(total_logical_bytes / 1024/1024/1024, 2) as size_gb,
  round(cost_monthly_forecast, 2) as estimated_monthly_cost
FROM {{ ref('most_expensive_tables') }}
ORDER BY cost_monthly_forecast DESC
LIMIT 10
```

### `unused_tables`

Identifies tables that are costing you money but haven't been touched in a long time. These are prime candidates for **archival** or **deletion**.

**Key Columns:**
*   `storage_last_modified_time`: When the data last changed.
*   `total_rows`: How big is it?
*   `storage_cost`: How much is it costing right now?

**📝 Example Query: "Find expensive tables untouched for 90 days"**

```sql
SELECT
  project_id,
  dataset_id,
  table_id,
  storage_last_modified_time,
  storage_cost
FROM {{ ref('unused_tables') }}
WHERE storage_last_modified_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  AND storage_cost > 5 -- Only care about tables costing > $5/month
ORDER BY storage_cost DESC
```

---

## 🔧 Optimization Opportunities

The package also provides "recommendation" views that simulate different pricing models.

*   **`query_with_better_pricing_using_flat_pricing_view`**: Identifies queries that would be cheaper if you purchased slots (Flat Rate / Editions).
*   **`table_with_better_pricing_on_physical_billing_model`**: Tables where you'd save money by switching from Logical (default) to Physical (compressed) storage billing.

**📝 Example Query: Potential Savings from Physical Storage**

```sql
SELECT
  project_id,
  dataset_id,
  table_id,
  logical_cost_monthly_forecast,
  physical_cost_monthly_forecast,
  (logical_cost_monthly_forecast - physical_cost_monthly_forecast) as potential_savings
FROM {{ ref('table_with_better_pricing_on_physical_billing_model') }}
WHERE (logical_cost_monthly_forecast - physical_cost_monthly_forecast) > 10
ORDER BY potential_savings DESC
```
