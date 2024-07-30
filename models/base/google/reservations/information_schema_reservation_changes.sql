
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservation-changes -#}
    
    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT change_timestamp, project_id, project_number, reservation_name, ignore_idle_slots, action, slot_capacity, user_email, target_job_concurrency, autoscale, edition
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATION_CHANGES`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT change_timestamp, project_id, project_number, reservation_name, ignore_idle_slots, action, slot_capacity, user_email, target_job_concurrency, autoscale, edition
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATION_CHANGES`
    
    {%- endif %}
    )
    SELECT
    change_timestamp, project_id, project_number, reservation_name, ignore_idle_slots, action, slot_capacity, user_email, target_job_concurrency, autoscale, edition,
    FROM
    base
    