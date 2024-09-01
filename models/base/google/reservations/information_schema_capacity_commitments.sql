
      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-capacity-commitments -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT ddl, project_id, project_number, capacity_commitment_id, commitment_plan, state, slot_count, edition, is_flat_rate, renewal_plan
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`CAPACITY_COMMITMENTS`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT ddl, project_id, project_number, capacity_commitment_id, commitment_plan, state, slot_count, edition, is_flat_rate, renewal_plan
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`CAPACITY_COMMITMENTS`
      {%- endif %}
      )
      SELECT
      ddl, project_id, project_number, capacity_commitment_id, commitment_plan, state, slot_count, edition, is_flat_rate, renewal_plan,
      FROM
      base
      