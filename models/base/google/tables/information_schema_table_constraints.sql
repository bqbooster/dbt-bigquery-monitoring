
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-constraints -#}
      {# Required role/permissions: You need the following
Identity and Access Management (IAM) permissions:
bigquery.tables.get for viewing primary and foreign key definitions.
bigquery.tables.list for viewing table information schemas.
Each of the following
predefined roles
has the needed permissions to perform the workflows detailed in this document:
roles/bigquery.dataEditor
roles/bigquery.dataOwner
roles/bigquery.admin
Note: Roles are presented in ascending order of permissions granted. We
recommend that you use predefined roles from earlier in the list to not allocate
excess permissions.For more information about IAM roles and permissions in
BigQuery, see
Predefined roles and permissions. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT constraint_catalog, constraint_schema, constraint_name, table_catalog, table_schema, table_name, constraint_type, is_deferrable, initially_deferred, enforced
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_CONSTRAINTS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT constraint_catalog, constraint_schema, constraint_name, table_catalog, table_schema, table_name, constraint_type, is_deferrable, initially_deferred, enforced
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_CONSTRAINTS`
      {%- endif %}
      )
      SELECT
      constraint_catalog, constraint_schema, constraint_name, table_catalog, table_schema, table_name, constraint_type, is_deferrable, initially_deferred, enforced,
      FROM
      base
      