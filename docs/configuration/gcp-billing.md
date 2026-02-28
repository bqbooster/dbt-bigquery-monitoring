---
sidebar_position: 5.3
slug: /configuration/gcp-billing
---

# GCP Billing export

GCP Billing export is a feature that allows you to export your billing data to BigQuery. It allows the package to track the real cost of your queries and storage overtime.

See the [configuration matrix](/configuration/configuration-matrix) for the full list of required variables.

To enable on GCP end, you can follow the [official documentation](https://cloud.google.com/billing/docs/how-to/export-data-bigquery) to set up the export.

Then enable the GCP billing export monitoring in the package, you'll need to define the following settings in the `dbt_project.yml` file:

```yml
vars:
  enable_gcp_billing_export: true
  gcp_billing_export_storage_project: 'my-gcp-project'
  gcp_billing_export_dataset: 'my_dataset'
  gcp_billing_export_table: 'my_table'
```
