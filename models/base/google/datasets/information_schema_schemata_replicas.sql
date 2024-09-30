{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-schemata-replicas -#}
      {# Required role/permissions: 
    
      To get the permissions that you need to query the INFORMATION_SCHEMA.SCHEMATA_REPLICAS view,
    
      ask your administrator to grant you the
    
  
  BigQuery Data Viewer  (roles/bigquery.dataViewer) IAM role on the project.
  

  
  
  For more information about granting roles, see Manage access to projects, folders, and organizations.
  
  
      You might also be able to get
      the required permissions through custom
      roles or other predefined
      roles.
     -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT catalog_name, schema_name, replica_name, location, replica_primary_assigned, replica_primary_assignment_complete, creation_time, creation_complete, replication_time
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_REPLICAS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT
catalog_name,
schema_name,
replica_name,
location,
replica_primary_assigned,
replica_primary_assignment_complete,
creation_time,
creation_complete,
replication_time
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA_REPLICAS`
      {%- endif %}
      )

SELECT
      catalog_name,
schema_name,
replica_name,
location,
replica_primary_assigned,
replica_primary_assignment_complete,
creation_time,
creation_complete,
replication_time,
      FROM
      base
