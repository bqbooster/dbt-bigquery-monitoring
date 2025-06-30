---
sidebar_position: 3
slug: /required-rights
---

# Required rights

To use this package, you will need to grant permissions to the Service Account that dbt uses to connect to BigQuery.

There are various ways to add required permissions to leverage the extension.

## "YOLO" mode

The simplest way is to give BQ admin access role:

- [BigQuery Admin](https://cloud.google.com/bigquery/docs/access-control#bigquery.admin) can do pretty much everything in BigQuery (so more than enough)

It's great for testing but not recommended for production where you'd rather follow the principle of least privilege.

## Finer grain basic roles

Google provides some predefined roles that can be used to grant the necessary permissions to the service account that dbt uses to connect to BigQuery.

Here's the list of predefined roles that can be combined to cover the extension needs:

- [BigQuery Data Editor](https://cloud.google.com/bigquery/docs/access-control#bigquery.dataEditor) to list and modify datasets/tables
- [BigQuery User](https://cloud.google.com/bigquery/docs/access-control#bigquery.user) to run queries
- [BigQuery Resource Viewer](https://cloud.google.com/bigquery/docs/access-control#bigquery.resourceViewer) to access some metadata tables

## Custom roles

if you prefer to use custom roles, you can use the following permissions.
This list might not be exhaustive and you might need to add more permissions depending on your use case but it should be a good start:

- **bigquery.jobs.create** - To Create BigQuery request
- **bigquery.tables.get** - To access BigQuery tables data
- **bigquery.tables.list** - To access BigQuery tables data
- **bigquery.jobs.listAll** - To access BigQuery jobs data

  - At the organization or project level, depending on desired scope
  - Note that JOBS_BY_ORGANIZATION is only available to users with defined Google Cloud organizations. More information on permissions and access control in BigQuery can be found [here](https://cloud.google.com/bigquery/docs/access-control).

- **bigquery.reservations.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- **bigquery.capacityCommitments.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
- **bigquery.reservationAssignments.list** - To [access BigQuery Reservations data](https://cloud.google.com/bigquery/docs/information-schema-reservations#required_permissions)
