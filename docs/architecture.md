---
sidebar_position: 6
slug: /architecture
---

This package aims to bring an easy way to:
- Access INFORMATION SCHEMA tables
- Bridge different INFORMATION SCHEMA tables, audit logs and billing logs together
- Create high level datamarts for queries and asset monitoring

# High level overview

```mermaid
flowchart LR
    subgraph Google tables
        information_schema_tables[INFORMATION SCHEMA tables]
        cloud_billing[Cloud Billing logs sink]
        cloud_audit[Cloud audit logs sink]
    end

    subgraph dbt-bigquery-monitoring
        subgraph base
            bigquery_audit_logs[bigquery_audit_logs]
            gcp_billing_export_resource_v1[gcp_billing_export_resource_v1]
            jobs_from_audit_logs[jobs_from_audit_logs]
            jobs_with_cost[jobs_with_cost]
            storage_with_cost[storage_with_cost]
            table_and_storage_with_cost[table_and_storage_with_cost]
        end

        subgraph intermediate
            intermediate_tables[intermediate tables]
        end

        subgraph datamarts
            datamarts_tables[datamarts_tables]
            dbt_bigquery_monitoring_options[dbt_bigquery_monitoring_options]
        end
    end

    cloud_billing --> gcp_billing_export_resource_v1
    cloud_audit --> bigquery_audit_logs
    bigquery_audit_logs --> jobs_from_audit_logs
    bigquery_audit_logs --> jobs_with_cost
    information_schema_tables --> jobs_with_cost
    jobs_from_audit_logs --> jobs_with_cost
    information_schema_tables --> storage_with_cost
    information_schema_tables --> table_and_storage_with_cost

	jobs_with_cost --> intermediate_tables
	storage_with_cost --> intermediate_tables
	gcp_billing_export_resource_v1 --> intermediate_tables

   intermediate_tables --> datamarts_tables

    classDef google fill:#f9d1c3,stroke:#e88366,color:#333
    classDef base fill:#c3e2f9,stroke:#66a9e8,color:#333
    classDef intermediate fill:#e2f9c3,stroke:#a9e866,color:#333
    classDef datamarts fill:#a2f9c3,stroke:#b91866,color:#333

    class information_schema_tables,cloud_billing,cloud_audit google

    class bigquery_audit_logs,gcp_billing_export_resource_v1,jobs_from_audit_logs,storage_with_cost,table_and_storage_with_cost,jobs_with_cost base

    class intermediate_tables intermediate

    class datamarts_tables,dbt_bigquery_monitoring_options datamarts
```
