
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-insights -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT insight_id, insight_type, subtype, project_id, project_number, description, last_updated_time, category, target_resources, state, severity, associated_recommendation_ids, additional_details
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`INSIGHTS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT insight_id, insight_type, subtype, project_id, project_number, description, last_updated_time, category, target_resources, state, severity, associated_recommendation_ids, additional_details
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`INSIGHTS`
      {%- endif %}
      )
      SELECT
      insight_id, insight_type, subtype, project_id, project_number, description, last_updated_time, category, target_resources, state, severity, associated_recommendation_ids, additional_details,
      FROM
      base
      