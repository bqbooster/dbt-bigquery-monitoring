---
slug: /configuration/configuration-matrix
---

# Configuration matrix

Use this matrix to validate required and optional variables or settings for each
setup scenario.

| Scenario | Required variables/settings | Optional variables/settings | Related docs |
| --- | --- | --- | --- |
| Region mode, single project | `bq_region` | `output_partition_expiration_days`, `use_flat_pricing`, `per_billed_tb_price` | [Package settings](/configuration/package-settings) |
| Project mode, multi-project | `input_gcp_projects` | `bq_region`, `output_partition_expiration_days`, `use_flat_pricing` | [Package settings](/configuration/package-settings) |
| Audit logs enabled | `enable_gcp_bigquery_audit_logs`, `gcp_bigquery_audit_logs_storage_project`, `gcp_bigquery_audit_logs_dataset`, `gcp_bigquery_audit_logs_table` | `should_combine_audit_logs_and_information_schema`, `google_information_schema_model_materialization` | [GCP BigQuery audit logs](/configuration/audit-logs) |
| Billing export enabled | `enable_gcp_billing_export`, `gcp_billing_export_storage_project`, `gcp_billing_export_dataset`, `gcp_billing_export_table` | `lookback_incremental_billing_window_days` | [GCP billing export](/configuration/gcp-billing) |
| Query metadata enabled | dbt settings `query-comment.comment` and `query-comment.job-label` | None | [dbt query comment docs](https://docs.getdbt.com/reference/project-configs/query-comment) |
