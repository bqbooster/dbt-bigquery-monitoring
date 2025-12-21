---
sidebar_position: 7
slug: /using-the-package
---

# Using the package

## Monitoring models (Datamarts)

> **💡 Want example queries?** Check out the [Monitoring Datamarts](/datamarts) guide for detailed examples and SQL recipes.

The package provides high-level datamarts designed to be easily consumed by BI tools (like Looker, Superset, Tableau) or for ad-hoc analysis. They are grouped by domain:

### 🌍 Global Overview

High-level metrics for executives and managers.

*   `global.daily_spend`: Aggregated daily cost for both Compute and Storage.
*   `global.dbt_bigquery_monitoring_options`: Current configuration of the package.

### ⚡ Compute Analysis

Analyze query costs, performance, and user behavior.

#### Costs & Pricing
*   `compute.cost.compute_cost_per_hour`: Detailed hourly breakdown of compute costs.
*   `compute.cost.compute_cost_per_minute`: Finer granularity for spotting cost spikes.
*   `compute.jobs.query_with_better_pricing_using_flat_pricing_view`: Identifies queries that would be cheaper under a flat-rate (slot-based) model.
*   `compute.jobs.query_with_better_pricing_using_on_demand_view`: Identifies queries that would be cheaper under on-demand pricing.

#### Performance & Top Consumers
*   `compute.jobs.most_expensive_jobs`: The top queries driving your bill.
*   `compute.jobs.most_repeated_jobs`: Identifies queries running too frequently (possible loop or scheduling error).
*   `compute.jobs.slowest_jobs`: Queries with the longest duration (latency analysis).
*   `compute.users.most_expensive_users`: Which users or service accounts spend the most?
*   `compute.models.most_expensive_models`: (Requires Query Comments) Which dbt models are the most expensive to run?

#### BI Engine
*   `compute.bi_engine.bi_engine_usage_per_minute`: Monitoring BI Engine acceleration and fallback rates.

### 💾 Storage Analysis

Monitor storage growth, costs, and optimization opportunities.

#### Costs & Optimization
*   `storage.storage_billing_per_hour`: Hourly storage costs.
*   `storage.dataset_with_cost`: Aggregated cost by dataset.
*   `storage.most_expensive_tables`: Top tables by storage cost.
*   `storage.unused_tables`: Tables that haven't been queried recently (candidates for deletion/archival).
*   `storage.read_heavy_tables`: Tables with high read/write ratios.

#### Billing Models
*   `storage.table_with_better_pricing_on_logical_billing_model`: Tables where logical (uncompressed) billing would be cheaper.
*   `storage.table_with_better_pricing_on_physical_billing_model`: Tables where physical (compressed) billing would be cheaper.

---

## Google INFORMATION_SCHEMA tables

The package exposes Google's `INFORMATION_SCHEMA` views as standard dbt models. This allows you to query metadata across multiple projects seamlessly.

> **Note**: These models are materialized as `ephemeral` (or `incremental` in project mode).

### Usage Example

```sql
SELECT query, total_bytes_billed
FROM {{ ref('information_schema_jobs') }}
WHERE creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
ORDER BY total_bytes_billed DESC
LIMIT 10
```

### Available Models Reference

(Prefix all refs with `information_schema_`)

**Jobs & Performance**
*   `jobs`, `jobs_by_project`, `jobs_by_user`, `jobs_by_folder`
*   `jobs_timeline` (visualize concurrency)

**Storage & Tables**
*   `tables`, `table_storage`, `table_snapshots`
*   `columns`, `column_field_paths` (schema details)
*   `partitions`

**Access & Security**
*   `object_privileges` (who can see what)
*   `search_indexes`, `vector_indexes`

**Configuration & Reservations**
*   `reservations`, `assignments` (slots management)
*   `bi_capacities` (BI Engine)
*   `effective_project_options`

...and many more mapping to the official [BigQuery Information Schema](https://cloud.google.com/bigquery/docs/information-schema-intro).
