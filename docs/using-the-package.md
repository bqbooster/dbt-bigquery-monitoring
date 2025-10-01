---
sidebar_position: 7
slug: /using-the-package
---

# Using the package

## Google INFORMATION_SCHEMA tables

Following models are available to query the INFORMATION_SCHEMA tables. They are materialized as `ephemeral` (or incremental tables in project mode) in dbt so it acts as a "source" but let you access multiple project based tables using a single `ref`.

### Example

You can use those models such as:

```sql
SELECT query FROM {{ ref('information_schema_jobs') }}
```

### All available google related models

Here's the list (**don't forget to prefix the following list by `information_schema_` in your `ref` call**).

- access_control

  - object_privileges

- bi_engine

  - bi_capacities
  - bi_capacity_changes

- configuration

  - effective_project_options
  - organization_options
  - organization_options_changes
  - project_options
  - project_options_changes

- datasets

  - links
  - schemata
  - schemata_options
  - schemata_replicas
  - shared_dataset_usage

- jobs

  - jobs
  - jobs_by_folder
  - jobs_by_organization
  - jobs_by_project
  - jobs_by_user

- jobs_timeline

  - jobs_timeline
  - jobs_timeline_by_folder
  - jobs_timeline_by_organization
  - jobs_timeline_by_user

- recommendations_and_insights

  - insights
  - recommendations_by_organization
  - recommendations

- reservations

  - assignment_changes
  - assignments
  - capacity_commitment_changes
  - capacity_commitments
  - reservation_changes
  - reservations
  - reservations_timeline

- routines

  - parameters
  - routine_options
  - routines

- search_indexes

  - search_index_columns
  - search_indexes

- sessions

  - sessions
  - sessions_by_project
  - sessions_by_user

- streaming

  - streaming_timeline
  - streaming_timeline_by_folder
  - streaming_timeline_by_organization

- tables

  - column_field_paths
  - columns
  - constraint_column_usage
  - key_column_usage
  - partitions
  - table_constraints
  - table_options
  - table_snapshots
  - table_storage
  - table_storage_by_organization
  - table_storage_usage_timeline
  - table_storage_usage_timeline_by_organization
  - tables

- vector_indexes

  - vector_index_columns
  - vector_index_options
  - vector_indexes

- views

  - materialized_views
  - views

- write_api

  - write_api_timeline
  - write_api_timeline_by_folder
  - write_api_timeline_by_organization

- gcp_billing_export

  - gcp_billing_export_resource_v1

## Monitoring models

The package provides the following datamarts that can be easily used to build monitoring charts and dashboards:

- global

  - daily_spend
  - dbt_bigquery_monitoring_options

- compute

  - billing
    - compute_billing_per_hour

  - bi engine
    - bi_engine_usage_per_minute
    - bi_engine_usage_per_hour

  - cost
    - compute_cost_per_hour
    - compute_cost_per_hour_view (adds computed metrics)
    - compute_cost_per_minute
    - compute_cost_per_minute_view (adds computed metrics)

  - jobs
    - most_expensive_jobs
    - most_repeated_jobs
    - slowest_jobs
    - query_with_better_pricing_using_flat_pricing_view
    - query_with_better_pricing_using_on_demand_view

  - models
    - most_expensive_models
    - most_repeated_models

  - reservations
    - reservation_usage_per_minute

  - users
    - most_expensive_users

- storage

  - dataset_with_better_pricing_on_logical_billing_model
  - dataset_with_better_pricing_on_physical_billing_model
  - dataset_with_cost
  - most_expensive_tables
  - partitions_monitoring
  - read_heavy_tables
  - storage_billing_per_hour
  - table_with_better_pricing_on_logical_billing_model
  - table_with_better_pricing_on_physical_billing_model
  - unused_tables
