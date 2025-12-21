<div align="center">
  <h1>
    dbt-bigquery-monitoring
  </h1>

  <h2>
    Monitor BigQuery performance and costs with dbt
  </h2>

  <div align="center">
    <a href="https://github.com/bqbooster/dbt-bigquery-monitoring/graphs/commit-activity"><img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/m/bqbooster/dbt-bigquery-monitoring"/></a>
    <a href="https://github.com/bqbooster/dbt-bigquery-monitoring/issues"><img alt="GitHub open issues" src="https://img.shields.io/github/issues/bqbooster/dbt-bigquery-monitoring"/></a>
    <a href="https://github.com/bqbooster/dbt-bigquery-monitoring/pulls"><img alt="GitHub open pull requests" src="https://img.shields.io/github/issues-pr/bqbooster/dbt-bigquery-monitoring"/></a>
    <a href="https://github.com/bqbooster/dbt-bigquery-monitoring/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/bqbooster/dbt-bigquery-monitoring"/></a>
    <a href="https://github.com/bqbooster/dbt-bigquery-monitoring/releases"><img alt="Latest Release" src="https://img.shields.io/github/v/release/bqbooster/dbt-bigquery-monitoring"/></a>
    <a href="https://github.com/bqbooster/dbt-bigquery-monitoring/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/bqbooster/dbt-bigquery-monitoring"/></a>
  </div>

  <p>
    <a href="https://bqbooster.github.io/dbt-bigquery-monitoring/"><strong>Documentation</strong></a>
    · <a href="https://bqbooster.github.io/dbt-bigquery-monitoring/installation">Installation</a>
    · <a href="https://bqbooster.github.io/dbt-bigquery-monitoring/configuration">Configuration</a>
    · <a href="https://bqbooster.github.io/dbt-bigquery-monitoring/running-the-package">Running</a>
    · <a href="https://bqbooster.github.io/dbt-bigquery-monitoring/using-the-package">Usage</a>
    · <a href="https://bqbooster.github.io/dbt-bigquery-monitoring/contributing">Contributing</a>
  </p>
</div>

*💡 Tip: Click on "Watch → Custom → Releases" to get email notifications for new versions with changelog details*

---

## 🚀 Overview

`dbt-bigquery-monitoring` provides a robust set of dbt models to help Analytics Engineers and Data Platform teams monitor, analyze, and optimize their BigQuery usage. It bridges **Information Schema**, **Audit Logs**, and **Billing Export** data to give you a complete view of your warehouse performance and costs.

### Key Features

*   **Cost Management**: Track spending by user, project, or query. Identify most expensive jobs and models.
*   **Performance Tuning**: Find bottlenecks, slow queries, and slot contention.
*   **Storage Analysis**: monitor logical vs physical storage costs, identify unused tables.
*   **Unified Metadata**: Abstract away the complexities of `INFORMATION_SCHEMA` with easy-to-use dbt models.
*   **BigQuery Edition Support**: Compatible with BigQuery Editions (Standard, Enterprise, Enterprise Plus).

---

## 🎯 Is this package for me?

Yes, if you need to:
*   Consolidate `INFORMATION_SCHEMA` views across a complex, multi-project GCP setup.
*   Monitor BigQuery compute and storage consumption via high-level datamarts.
*   Discover cost-saving opportunities (e.g., switching billing models, optimizing queries).
*   Trace lineage and usage of columns and tables effectively.

---

## ⚡ Quick Start

### 1. Install

Add to your `packages.yml`:

```yml
packages:
  - package: bqbooster/dbt_bigquery_monitoring
    version: 0.24.0 # Check for the latest version
```

### 2. Configure

Add to your `dbt_project.yml`:

```yml
models:
  dbt_bigquery_monitoring:
    +schema: "monitoring" # Creates tables in <your_schema>_monitoring

vars:
  bq_region: 'us' # Your dataset region
```

### 3. Run

```bash
dbt deps
dbt run -s dbt_bigquery_monitoring
```

---

## 🛠 Compatibility

*   **dbt Core** >= 1.3.0
*   **dbt Fusion** >= 2.0.0-beta

---

## 📖 Full Documentation

For detailed configuration, advanced usage, and architecture diagrams, check out the [Official Documentation](https://bqbooster.github.io/dbt-bigquery-monitoring/).
