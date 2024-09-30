{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservations -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT ddl, project_id, project_number, reservation_name, ignore_idle_slots, slot_capacity, target_job_concurrency, autoscale, edition
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATIONS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT
ddl,
project_id,
project_number,
reservation_name,
ignore_idle_slots,
slot_capacity,
target_job_concurrency,
autoscale,
edition
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATIONS`
      {%- endif %}
      )

SELECT
      ddl,
project_id,
project_number,
reservation_name,
ignore_idle_slots,
slot_capacity,
target_job_concurrency,
autoscale,
edition,
      FROM
      base
