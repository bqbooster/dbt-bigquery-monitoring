
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-effective-project-options -#}
      {# Required role/permissions: To get effective project options metadata, you need the bigquery.config.get
Identity and Access Management (IAM) permission.The following predefined IAM role includes the
permissions that you need in order to get effective project options metadata:
roles/bigquery.jobUser
For more information about granular BigQuery permissions, see
roles and permissions. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT option_name, option_description, option_type, option_set_level, option_set_on_id
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`EFFECTIVE_PROJECT_OPTIONS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT option_name, option_description, option_type, option_set_level, option_set_on_id
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`EFFECTIVE_PROJECT_OPTIONS`
      {%- endif %}
      )
      SELECT
      option_name, option_description, option_type, option_set_level, option_set_on_id,
      FROM
      base
      