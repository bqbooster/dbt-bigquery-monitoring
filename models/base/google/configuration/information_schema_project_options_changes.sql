
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-project-options-changes -#}
      {# Required role/permissions: To get the configuration, you need the bigquery.config.update
Identity and Access Management (IAM) permission at the project level. The predefined
IAM role roles/bigquery.admin includes the permissions that you
need to create a configuration.For more information about granular BigQuery permissions, see
roles and permissions. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT update_time, username, updated_options, project_id, project_number
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`PROJECT_OPTIONS_CHANGES`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT update_time, username, updated_options, project_id, project_number
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`PROJECT_OPTIONS_CHANGES`
      {%- endif %}
      )
      SELECT
      update_time, username, updated_options, project_id, project_number,
      FROM
      base
      