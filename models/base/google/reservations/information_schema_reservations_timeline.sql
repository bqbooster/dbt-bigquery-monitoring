
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-reservation-timeline -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT period_start, project_id, project_number, reservation_name, ignore_idle_slots, slots_assigned, slots_max_assigned, autoscale, reservation_id
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATIONS_TIMELINE`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT period_start, project_id, project_number, reservation_name, ignore_idle_slots, slots_assigned, slots_max_assigned, autoscale, reservation_id
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`RESERVATIONS_TIMELINE`
      {%- endif %}
      )
      SELECT
      period_start, project_id, project_number, reservation_name, ignore_idle_slots, slots_assigned, slots_max_assigned, autoscale, reservation_id,
      FROM
      base
      