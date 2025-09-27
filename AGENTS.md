# AGENTS Guide

This document distills the essential knowledge from `docs/` so automated agents can navigate the repository quickly and act safely. Use it as the canonical reference before taking any action.

## Package Overview
- The repository hosts the `dbt-bigquery-monitoring` dbt package, which delivers models for monitoring Google BigQuery performance and spend (`docs/intro.md`).
- Documentation for the public site lives in `docs/` and is built with Docusaurus (`docs/contributing.md`).

## Architecture Highlights
- Source data comes from INFORMATION_SCHEMA tables, Cloud Billing export, and Cloud Audit logs.
- Base models consolidate raw data; intermediate layers prepare metrics; datamarts surface monitoring-friendly tables (`docs/architecture.md`).
- Key base models include `jobs_with_cost`, `storage_with_cost`, and `gcp_billing_export_resource_v1`.

## Access Requirements
- Running the package requires a service account with permissions to query BigQuery jobs, tables, reservations, and billing exports.
- Minimal predefined roles: BigQuery Data Editor, BigQuery User, and BigQuery Resource Viewer.
- Custom role must include `bigquery.jobs.create`, `bigquery.jobs.listAll`, and related table/reservation read permissions (`docs/required-rights.md`).

## Installation Steps
- Add the package to `packages.yml`:
  ```yml
  packages:
    - package: bqbooster/dbt_bigquery_monitoring
      version: 0.23.0
  ```
- Set the target schema in `dbt_project.yml` under the `dbt_bigquery_monitoring` namespace (`docs/installation.md`).

## Execution Modes
- **Region mode** keeps INFORMATION_SCHEMA models ephemeral; schedule runs only for datamarts.
- **Project mode** persists consolidated tables and requires scheduled runs for both base and datamart models.
- Incremental models expect hourly scheduling for best cost/performance balance (`docs/running-the-package.md`).

### Recommended Commands
- Datamarts only: `dbt run -s +tag:dbt-bigquery-monitoring-datamarts`
- INFORMATION_SCHEMA consolidation: `dbt run -s +tag:dbt-bigquery-monitoring-information-schema`
- Full stack: `dbt run -s +tag:dbt-bigquery-monitoring`
- CI environments should typically exclude the package: `dbt run --exclude tag:dbt-bigquery-monitoring`

## Model Catalog
- INFORMATION_SCHEMA wrappers cover jobs, reservations, tables, datasets, sessions, and more. Reference them via `{{ ref('information_schema_<name>') }}`.
- Datamarts deliver spend, compute, storage, reservation, and usage aggregates such as `compute_cost_per_hour`, `most_expensive_jobs`, and `storage_billing_per_hour` (`docs/using-the-package.md`).

## Contributor Workflow
- Preferred tooling: pipx, SQLFluff, changie, and pre-commit (`docs/contributing.md`).
- Standard flow: fork → branch → develop → run tests and lint (`sqlfluff lint`) → generate changelog (`changie new`) → commit → PR.

## Agent Operating Principles
- Respect existing docs and configuration; mirror public documentation when generating new content.
- Before editing SQL, ensure linting compatibility (`sqlfluff`) and maintain incremental model conventions.
- Confirm scheduling or permission guidance aligns with sections above; diverge only with explicit user approval.
- When unsure, surface clarifying questions with references to affected sections in this guide.


