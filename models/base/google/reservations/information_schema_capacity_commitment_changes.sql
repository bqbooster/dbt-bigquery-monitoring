{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-capacity-commitment-changes -#}
WITH base AS (
{% if project_list()|length > 0 -%}
  {% for project in project_list() -%}
  SELECT * FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`CAPACITY_COMMITMENT_CHANGES`
  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
{%- else %}
  SELECT * FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`CAPACITY_COMMITMENT_CHANGES`
{%- endif %}
)
SELECT
change_timestamp,
project_id,
project_number,
capacity_commitment_id,
commitment_plan,
state,
slot_count,
action,
user_email,
commitment_start_time,
commitment_end_time,
failure_status,
renewal_plan,
edition,
is_flat_rate,
FROM
  base
