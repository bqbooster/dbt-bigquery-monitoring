
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-organization-options-changes -#}
    {# Required role/permissions: 
    
      To get the permission that you need to get the configuration changes,
    
      ask your administrator to grant you the
    
  
  BigQuery Admin  (roles/bigquery.admin) IAM role on your organization.
  

  
  
  For more information about granting roles, see Manage access.
  
   -#}

    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT update_time, username, updated_options, project_id, project_number
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ORGANIZATION_OPTIONS_CHANGES`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT update_time, username, updated_options, project_id, project_number
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ORGANIZATION_OPTIONS_CHANGES`
    
    {%- endif %}
    )
    SELECT
    update_time, username, updated_options, project_id, project_number,
    FROM
    base
    