{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-assignments -#}

WITH base AS (
  {% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT ddl, project_id, project_number, assignment_id, reservation_name, job_type, assignee_id, assignee_number, assignee_type
  FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ASSIGNMENTS`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT
ddl,
project_id,
project_number,
assignment_id,
reservation_name,
job_type,
assignee_id,
assignee_number,
assignee_type
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ASSIGNMENTS`
{%- endif %}
)

SELECT
ddl,
project_id,
project_number,
assignment_id,
reservation_name,
job_type,
assignee_id,
assignee_number,
assignee_type,
FROM
base
