{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-effective-project-options -#}
{# Required role/permissions: To get effective project options metadata, you need the bigquery.config.get
Identity and Access Management (IAM) permission.The following predefined IAM role includes the
permissions that you need in order to get effective project options metadata:
roles/bigquery.jobUser
For more information about granular BigQuery permissions, see
roles and permissions. -#}

SELECT
option_name,
option_description,
option_type,
option_set_level,
option_set_on_id
FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`EFFECTIVE_PROJECT_OPTIONS`
