{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-assignments-changes -#}

WITH base AS (
  {% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT change_timestamp, project_id, project_number, assignment_id, reservation_name, job_type, assignee_id, assignee_number, assignee_type, action, user_email, state
  FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ASSIGNMENT_CHANGES`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT
change_timestamp,
project_id,
project_number,
assignment_id,
reservation_name,
job_type,
assignee_id,
assignee_number,
assignee_type,
action,
user_email,
state
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`ASSIGNMENT_CHANGES`
{%- endif %}
)

SELECT
change_timestamp,
project_id,
project_number,
assignment_id,
reservation_name,
job_type,
assignee_id,
assignee_number,
assignee_type,
action,
user_email,
state,
FROM
base
