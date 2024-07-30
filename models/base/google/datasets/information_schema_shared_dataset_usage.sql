
    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-shared-dataset-usage -#}
    
    WITH base AS (
    {% if project_list()|length > 0 -%}
        {% for project in project_list() -%}
        
    SELECT project_id, dataset_id, table_id, data_exchange_id, listing_id, job_start_time, job_end_time, job_id, job_project_number, job_location, linked_project_number, linked_dataset_id, subscriber_org_number, subscriber_org_display_name, num_rows_processed, total_bytes_processed
    FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SHARED_DATASET_USAGE`
    
        {% if not loop.last %}UNION ALL{% endif %}
        {% endfor %}
    {%- else %}
        
    SELECT project_id, dataset_id, table_id, data_exchange_id, listing_id, job_start_time, job_end_time, job_id, job_project_number, job_location, linked_project_number, linked_dataset_id, subscriber_org_number, subscriber_org_display_name, num_rows_processed, total_bytes_processed
    FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SHARED_DATASET_USAGE`
    
    {%- endif %}
    )
    SELECT
    project_id, dataset_id, table_id, data_exchange_id, listing_id, job_start_time, job_end_time, job_id, job_project_number, job_location, linked_project_number, linked_dataset_id, subscriber_org_number, subscriber_org_display_name, num_rows_processed, total_bytes_processed,
    FROM
    base
    