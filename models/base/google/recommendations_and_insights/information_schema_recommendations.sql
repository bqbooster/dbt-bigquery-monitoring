
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-recommendations -#}
    
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
    