
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs-timeline-by-folder -#}
      {# Required role/permissions: To query the INFORMATION_SCHEMA.JOBS_TIMELINE_BY_FOLDER view, you need
the bigquery.jobs.listAll Identity and Access Management (IAM) permission for the parent
folder. Each of the following predefined IAM roles includes the
required permission:
Folder Admin
BigQuery Admin
For more information about BigQuery permissions, see
Access control with IAM. -#}

      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT period_start, period_slot_ms, period_shuffle_ram_usage_ratio, project_id, project_number, folder_numbers, user_email, job_id, job_type, statement_type, job_creation_time, job_start_time, job_end_time, state, reservation_id, edition, total_bytes_processed, error_result, cache_hit, period_estimated_runnable_units
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_TIMELINE_BY_FOLDER`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT period_start, period_slot_ms, period_shuffle_ram_usage_ratio, project_id, project_number, folder_numbers, user_email, job_id, job_type, statement_type, job_creation_time, job_start_time, job_end_time, state, reservation_id, edition, total_bytes_processed, error_result, cache_hit, period_estimated_runnable_units
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`JOBS_TIMELINE_BY_FOLDER`
      {%- endif %}
      )
      SELECT
      period_start, period_slot_ms, period_shuffle_ram_usage_ratio, project_id, project_number, folder_numbers, user_email, job_id, job_type, statement_type, job_creation_time, job_start_time, job_end_time, state, reservation_id, edition, total_bytes_processed, error_result, cache_hit, period_estimated_runnable_units,
      FROM
      base
      