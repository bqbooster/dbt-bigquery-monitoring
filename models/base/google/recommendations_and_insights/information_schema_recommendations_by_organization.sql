
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-recommendations-by-org -#}
    {# Required role/permissions: To view recommendations with the
INFORMATION_SCHEMA.RECOMMENDATIONS_BY_ORGANIZATION view, you must have the
required permissions for the corresponding recommender. The
INFORMATION_SCHEMA.RECOMMENDATIONS_BY_ORGANIZATION view only returns
recommendations that you have permission to view. When you have the required
permissions on the organization, you can view recommendations for all projects
within that organization, regardless of your permissions on the project itself.Ask your administrator to grant access to view the recommendations. To see the
required permissions for each recommender, see the following:
Partition & cluster recommender permissions
Materialized view recommendations permissions
Role recommendations for datasets permissions
 -#}

    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT recommendation_id, recommender, subtype, project_id, project_number, description, last_updated_time, target_resources, state, primary_impact, priority, associated_insight_ids, additional_details
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RECOMMENDATIONS`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT recommendation_id, recommender, subtype, project_id, project_number, description, last_updated_time, target_resources, state, primary_impact, priority, associated_insight_ids, additional_details
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RECOMMENDATIONS`
    
    {%- endif %}
    )
    SELECT
    recommendation_id, recommender, subtype, project_id, project_number, description, last_updated_time, target_resources, state, primary_impact, priority, associated_insight_ids, additional_details,
    FROM
    base
    