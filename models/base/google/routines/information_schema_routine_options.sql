{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-routine-options -#}
      {# Required role/permissions: To query the INFORMATION_SCHEMA.ROUTINE_OPTIONS view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.routines.get
bigquery.routines.list
Each of the following predefined IAM roles includes the
permissions that you need in order to get routine metadata:
roles/bigquery.admin
roles/bigquery.metadataViewer
roles/bigquery.dataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT specific_catalog, specific_schema, specific_name, option_name, option_type, option_value
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ROUTINE_OPTIONS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT
specific_catalog,
specific_schema,
specific_name,
option_name,
option_type,
option_value
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ROUTINE_OPTIONS`
      {%- endif %}
      )

SELECT
      specific_catalog,
specific_schema,
specific_name,
option_name,
option_type,
option_value,
      FROM
      base
