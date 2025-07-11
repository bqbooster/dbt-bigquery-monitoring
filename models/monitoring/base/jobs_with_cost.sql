{{
   config(
    materialized=materialized_as_view_if_explicit_projects()
    )
}}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs -#}
WITH
source AS (
  SELECT *,
 {%- if dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() and should_combine_audit_logs_and_information_schema() %}
  FROM {{ ref('combined_jobs_inputs') }}
 {%- elif dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() %}
  NULL AS job_stages,
  NULL AS parent_job_id,
  NULL AS timeline,
  NULL AS total_bytes_billed,
  NULL AS total_bytes_processed,
  NULL AS transaction_id,
  NULL AS query_info,
  NULL AS transferred_bytes,
  NULL AS materialized_view_statistics,
  NULL AS edition,
  NULL AS session_info,
  FROM {{ ref('jobs_from_audit_logs') }}
 {%- else %}
  NULL AS caller_supplied_user_agent,
  FROM {{ ref('information_schema_jobs') }}
 {%- endif %}
),

base AS (
SELECT
  bi_engine_statistics,
  cache_hit,
  caller_supplied_user_agent,
  creation_time,
  {%- if dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() and should_combine_audit_logs_and_information_schema() %}
  hour
  {%- elif dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() %}
  TIMESTAMP_TRUNC(timestamp, HOUR)
 {%- else %}
  TIMESTAMP_TRUNC(creation_time, HOUR)
 {%- endif %}
   AS hour,
  destination_table,
  edition,
  end_time,
  error_result,
  job_id,
  job_stages,
  job_type,
  labels,
  parent_job_id,
  priority,
  project_id,
  project_number,
  query,
  -- extract the dbt info from the query comment generated by dbt
  REPLACE(REPLACE(REGEXP_EXTRACT(query, r'^(\/\* \{+?[\w\W]+?\} \*\/)'), '/', ''), '*', '') AS dbt_info,
  referenced_tables,
  reservation_id,
  session_info,
  start_time,
  state,
  statement_type,
  timeline,
  total_bytes_billed,
  total_bytes_processed,
  total_modified_partitions,
  total_slot_ms,
  transaction_id,
  user_email,
  query_info,
  transferred_bytes,
  materialized_view_statistics
FROM source
{#- Prevent to duplicate costs as script contains query #}
WHERE statement_type != 'SCRIPT'
),

base_with_enriched_fields AS (
SELECT
  *,
  total_slot_ms / (1000 * 60 * 60 * 24) AS avg_slots,
  total_bytes_billed / POW(1024, 4) AS total_tb_billed,
  TIMESTAMP_DIFF(COALESCE(end_time, CURRENT_TIMESTAMP()), start_time, SECOND) AS total_time_seconds,
  IF(LENGTH(dbt_info) > 0, JSON_EXTRACT_SCALAR(dbt_info, '$.dbt_version'), NULL) AS dbt_version,
  IF(LENGTH(dbt_info) > 0, JSON_EXTRACT_SCALAR(dbt_info, '$.profile_name'), NULL) AS dbt_profile_name,
  IF(LENGTH(dbt_info) > 0, JSON_EXTRACT_SCALAR(dbt_info, '$.target_name'), NULL) AS dbt_target_name,
  IF(LENGTH(dbt_info) > 0, JSON_EXTRACT_SCALAR(dbt_info, '$.node_id'), NULL) AS dbt_model_name,
  IF(LENGTH(dbt_info) > 0,
  ARRAY(
  SELECT JSON_VALUE(string_element, '$')
  FROM UNNEST(JSON_QUERY_ARRAY(dbt_info, '$.node_tags')) AS string_element
  ), NULL) AS node_tags,
  CASE
  WHEN EXISTS (SELECT 1 FROM UNNEST(labels) WHERE key = 'dbt_invocation_id' AND value IS NOT NULL) THEN 'dbt'
  WHEN EXISTS (SELECT 1 FROM UNNEST(labels) WHERE key LIKE 'looker-%' AND value IS NOT NULL) THEN 'Looker'
  WHEN EXISTS (SELECT 1 FROM UNNEST(labels) WHERE key = 'sheets_trigger' AND value = 'user') THEN 'Google connected sheets - manual'
  WHEN EXISTS (SELECT 1 FROM UNNEST(labels) WHERE key = 'sheets_trigger' AND value = 'schedule') THEN 'Google connected sheets - scheduled'
  WHEN EXISTS (SELECT 1 FROM UNNEST(labels) WHERE key = 'data_source_id' AND value = 'scheduled_query') THEN 'Scheduled query'
  WHEN EXISTS (SELECT 1 FROM UNNEST(labels) WHERE key = 'client_type') THEN (SELECT value FROM UNNEST(labels) WHERE key = 'client_type' LIMIT 1)
  {%- if dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() %}
  WHEN caller_supplied_user_agent LIKE 'dbt%' THEN 'dbt run'
  WHEN caller_supplied_user_agent LIKE 'Fivetran%' THEN 'Fivetran'
  WHEN caller_supplied_user_agent LIKE 'gcloud-golang-bigquery%' AND user_email LIKE 'rudderstack%' THEN 'Rudderstack'
  WHEN caller_supplied_user_agent LIKE 'gcloud-golang%' OR caller_supplied_user_agent LIKE 'google-api-go%' THEN 'Golang Client'
  WHEN caller_supplied_user_agent LIKE 'gcloud-node%' THEN 'Node Client'
  WHEN caller_supplied_user_agent LIKE 'gl-python%' THEN 'Python Client'
  WHEN caller_supplied_user_agent LIKE 'google-cloud-sdk%' THEN 'Google Cloud SDK'
  WHEN caller_supplied_user_agent LIKE 'Hightouch%' THEN 'Hightouch'
  WHEN caller_supplied_user_agent LIKE 'Mozilla%' THEN 'Web console'
  WHEN caller_supplied_user_agent LIKE 'SimbaJDBCDriver%' THEN 'Java Client'
  ELSE coalesce(caller_supplied_user_agent, 'Unknown')
  {%- else %}
  ELSE 'Unknown'
  {% endif %}
  END AS client_type,
FROM base
),

base_with_all_pricing AS (
SELECT
  * EXCEPT (dbt_model_name),
    total_slot_ms / (1000 * 60 * 60) * {{ dbt_bigquery_monitoring_variable_hourly_slot_price() }} AS flat_pricing_query_cost,
    total_tb_billed * {{ dbt_bigquery_monitoring_variable_per_billed_tb_price() }} AS ondemand_query_cost,
    CASE
        WHEN dbt_model_name LIKE 'model.%' THEN 'model'
        WHEN dbt_model_name LIKE 'snapshot.%' THEN 'snapshot'
        WHEN dbt_model_name LIKE 'test.%' THEN 'test'
    END AS dbt_execution_type,
    CONCAT(SPLIT(dbt_model_name, '.')[SAFE_OFFSET(1)], '.', SPLIT(dbt_model_name, '.')[SAFE_OFFSET(2)]) AS dbt_model_name
FROM base_with_enriched_fields
)

SELECT
 *,
{% if dbt_bigquery_monitoring_variable_use_flat_pricing() -%}
  flat_pricing_query_cost AS query_cost
{%- else -%}
  ondemand_query_cost AS query_cost
{%- endif %}
FROM base_with_all_pricing
