---
sidebar_position: 2
slug: /architecture
---

# Architecture

`dbt-bigquery-monitoring` is a dbt package that ingests raw BigQuery metadata from multiple
GCP sources and transforms it into business-ready monitoring tables.

## Data flow

```mermaid
flowchart LR
    subgraph GCP["Google Cloud (sources)"]
        IS["INFORMATION_SCHEMA\n(JOBS, TABLES, STORAGE…)"]
        CA["Cloud Audit Logs sink\n(cloudaudit_googleapis_com_data_access)"]
        CB["Cloud Billing export\n(gcp_billing_export_resource_v1)"]
    end

    subgraph PKG["dbt-bigquery-monitoring"]
        subgraph base["Base layer (ephemeral / incremental)"]
            BAL["bigquery_audit_logs_v2"]
            BEX["gcp_billing_export_resource_v1"]
            JFL["jobs_from_audit_logs"]
            JWC["jobs_with_cost"]
            SWC["storage_with_cost"]
            TWC["table_and_storage_with_cost"]
        end

        subgraph intermediate["Intermediate layer"]
            INT["per-project consolidated tables\n(project mode only)"]
        end

        subgraph datamarts["Datamarts (output)"]
            DM["most_expensive_jobs\nmost_expensive_users\nmost_expensive_models\ndaily_spend\nunused_tables\n…"]
            OPT["dbt_bigquery_monitoring_options\n(current config snapshot)"]
        end
    end

    IS --> JWC
    IS --> SWC
    IS --> TWC
    CA --> BAL
    BAL --> JFL
    JFL --> JWC
    CB --> BEX
    BEX --> INT

    JWC --> INT
    SWC --> INT
    TWC --> INT

    INT --> DM
    INT --> OPT

    classDef google fill:#f9d1c3,stroke:#e88366,color:#333
    classDef base fill:#c3e2f9,stroke:#66a9e8,color:#333
    classDef intermediate fill:#fff3cd,stroke:#ffc107,color:#333
    classDef datamarts fill:#d4edda,stroke:#28a745,color:#333

    class IS,CA,CB google
    class BAL,BEX,JFL,JWC,SWC,TWC base
    class INT intermediate
    class DM,OPT datamarts
```

---

## Layer descriptions

### Base layer

Raw data ingestion and standardization. Each model corresponds to one GCP source:

| Model | Source | Description |
|---|---|---|
| `bigquery_audit_logs_v2` | Cloud Audit Logs | Raw v2 audit log events (jobs, table changes, etc.) |
| `jobs_from_audit_logs` | ↑ | Extracts structured job records from audit log events |
| `gcp_billing_export_resource_v1` | Cloud Billing export | Detailed SKU-level billing records |
| `jobs_with_cost` | IS + Audit logs | **Central model** — unified job view with cost attribution |
| `storage_with_cost` | INFORMATION_SCHEMA | Table storage metrics with storage cost |
| `table_and_storage_with_cost` | INFORMATION_SCHEMA | Per-table storage with billing model details |

### Intermediate layer

In **project mode**, INFORMATION_SCHEMA tables cannot be queried across projects in a single
BigQuery job. The intermediate layer materializes results project-by-project using the
`project_by_project_table` custom materialization, then consolidates them into unified tables.

In **region mode**, this layer is ephemeral — models resolve directly as subqueries.

### Datamarts

High-level, business-ready output tables designed for direct BI tool consumption or ad-hoc queries.
See [Using the package](/using-the-package) and [Monitoring Datamarts](/datamarts) for details.

---

## Materialization strategy

| Layer | Region mode | Project mode |
|---|---|---|
| INFORMATION_SCHEMA wrappers | `ephemeral` | `incremental` (per project) |
| Base models | `ephemeral` | `ephemeral` |
| `jobs_with_cost` | `incremental` | `incremental` |
| Datamarts | `table` (configurable) | `table` (configurable) |

The `output_materialization` variable controls the datamart materialization type
(see [package settings](/configuration/package-settings)).
