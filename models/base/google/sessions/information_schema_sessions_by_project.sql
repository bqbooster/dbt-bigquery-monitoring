
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-sessions-by-project -#}
      {# Required role/permissions: To query the INFORMATION_SCHEMA.SESSIONS_BY_PROJECT view, you need
the bigquery.jobs.listAll Identity and Access Management (IAM) permission for the project.
Each of the following predefined IAM roles includes the
required permission:
Project Owner
BigQuery Admin
For more information about BigQuery permissions, see
Access control with IAM. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT creation_time, expiration_time, is_active, last_modified_time, principal_subject, project_id, project_number, session_id, user_email
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SESSIONS_BY_PROJECT`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT creation_time, expiration_time, is_active, last_modified_time, principal_subject, project_id, project_number, session_id, user_email
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SESSIONS_BY_PROJECT`
      {%- endif %}
      )
      SELECT
      creation_time, expiration_time, is_active, last_modified_time, principal_subject, project_id, project_number, session_id, user_email,
      FROM
      base
      