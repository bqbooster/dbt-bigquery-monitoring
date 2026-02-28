---
slug: /configuration/configuration-matrix
---

# Configuration matrix

Use this matrix to validate required and optional variables for each setup
scenario.

| Scenario | Required vars | Optional vars | Related docs |
| --- | --- | --- | --- |
| Region mode, single project | `bq_region` | `dbt_bq_monitoring_source_table_expiration_days`, pricing vars | [Package settings](/configuration/package-settings) |
| Project mode, multi-project | `input_gcp_projects` | `bq_region`, expiration and pricing vars | [Package settings](/configuration/package-settings) |
| Audit logs enabled | `input_audit_logs_table` | filters and parsing flags | [GCP BigQuery audit logs](/configuration/audit-logs) |
| Billing export enabled | `input_billing_export_resource_v1` or `input_billing_export_resource_v2` | invoice-month and enrichment vars | [GCP billing export](/configuration/gcp-billing) |
| Query metadata enabled | `query-comment.comment`, `query-comment.job-label` | none | [dbt query comment docs](https://docs.getdbt.com/reference/project-configs/query-comment) |
