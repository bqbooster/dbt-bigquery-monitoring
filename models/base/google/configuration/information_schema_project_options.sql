{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-project-options -#}
{# Required role/permissions: To get configuration options metadata, you need the following Identity and Access Management (IAM) permissions:
bigquery.config.get
The following predefined IAM role includes the
permissions that you need in order to get project options metadata:
roles/bigquery.jobUser
For more information about granular BigQuery permissions, see
roles and permissions. -#}

SELECT option_name, option_description, option_type, option_value
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`PROJECT_OPTIONS`