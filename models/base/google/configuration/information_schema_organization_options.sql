{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-organization-options -#}
      {# Required role/permissions: To get organization options metadata, you need the following Identity and Access Management (IAM) permissions:
bigquery.config.get
The following predefined IAM role includes the
permissions that you need in order to get organization options metadata:
roles/bigquery.jobUser
For more information about granular BigQuery permissions, see
roles and permissions. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT option_name, option_description, option_type, option_value
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ORGANIZATION_OPTIONS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT
option_name,
option_description,
option_type,
option_value
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ORGANIZATION_OPTIONS`
      {%- endif %}
      )

SELECT
      option_name,
option_description,
option_type,
option_value,
      FROM
      base
