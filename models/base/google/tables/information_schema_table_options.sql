
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-options -#}
      {# Required role/permissions: To query the INFORMATION_SCHEMA.TABLE_OPTIONS view, you need the following
Identity and Access Management (IAM) permissions:
bigquery.tables.get
bigquery.tables.list
bigquery.routines.get
bigquery.routines.list
Each of the following predefined IAM roles includes the preceding
permissions:
roles/bigquery.admin
roles/bigquery.dataViewer
roles/bigquery.metadataViewer
For more information about BigQuery permissions, see
Access control with IAM. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT table_catalog, table_schema, table_name, option_name, option_type, option_value
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_OPTIONS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT table_catalog, table_schema, table_name, option_name, option_type, option_value
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_OPTIONS`
      {%- endif %}
      )
      SELECT
      table_catalog, table_schema, table_name, option_name, option_type, option_value,
      FROM
      base
      