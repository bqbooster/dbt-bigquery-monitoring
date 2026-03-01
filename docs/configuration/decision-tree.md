---
slug: /configuration/decision-tree
---

# Choosing your configuration

Answer these questions to pick the right setup for your environment.

1. If your execution project and storage project are the same, start in **region
   mode** with `bq_region`. See [Region mode](/configuration#region-mode-default).
2. If you monitor multiple projects or separate execution and storage projects,
   use **project mode** with `input_gcp_projects`. See [Project mode](/configuration#project-mode).
3. If you want full cost and governance coverage, enable both audit logs and
   billing export.
4. If you want model metadata in jobs, enable query comments. See
   [Add metadata to queries](/configuration#add-metadata-to-queries-recommended-but-optional).
5. If you need pricing and advanced package controls, configure package
   settings.

Then continue with the detailed pages:

- Baseline and variable setup: [configuration matrix](/configuration/configuration-matrix)
- Audit logs configuration: [GCP BigQuery audit logs](/configuration/audit-logs)
- Billing configuration: [GCP billing export](/configuration/gcp-billing)
- Variable reference: [package settings](/configuration/package-settings)
