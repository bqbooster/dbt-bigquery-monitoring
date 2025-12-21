---
sidebar_position: 1
slug: /
---

# Introduction

**dbt-bigquery-monitoring** is a comprehensive dbt package designed to help you **master your BigQuery usage**, from cost allocation to performance tuning.

By leveraging metadata from **Information Schema**, **Audit Logs**, and **Billing Exports**, this package provides actionable insights into your data warehouse.

## Why use this package?

In a modern data stack, BigQuery costs and performance complexity can grow rapidly. This package solves common challenges:

*   **Unified Visibility**: aggregating metadata from dozens of GCP projects into a single view.
*   **Cost Clarity**: identifying exactly *who* (user/service account) and *what* (dbt model/query) is driving costs.
*   **Performance Optimization**: pinpointing slow queries, slot contention, and inefficient partitioned tables.
*   **Data Lineage**: exposing column-level usage and dependencies via standard dbt docs.

## How it works

The package works by ingesting raw metadata logs and transforming them into:
1.  **Base Models**: Cleaned and standardized logs.
2.  **Intermediate Models**: Enriched data (e.g. joining jobs with their cost).
3.  **Datamarts**: High-level tables ready for BI tools (e.g. `compute_cost_per_hour`, `most_expensive_models`).

> ➡️ See the [Architecture](/architecture) page for a detailed diagram.

## dbt compatibility

The package is actively maintained and tested with:
*   **dbt Core** >= 1.3.0
*   **dbt Fusion** >= 2.0.0-beta

It is currently used in production with dbt 1.9.x.
