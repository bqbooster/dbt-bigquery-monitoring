{{
   config(
    materialized = "ephemeral",
    enabled = dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs() and should_combine_audit_logs_and_information_schema()
    )
}}

SELECT
  COALESCE(TIMESTAMP_TRUNC(a.timestamp, HOUR), TIMESTAMP_TRUNC(j.creation_time, HOUR)) AS hour,
  j.bi_engine_statistics AS bi_engine_statistics, -- this field is only available in information schema
  COALESCE(a.cache_hit, j.cache_hit) AS cache_hit,
  a.caller_supplied_user_agent AS caller_supplied_user_agent, -- this field is only available in the audit logs
  COALESCE(a.creation_time, j.creation_time) AS creation_time,
  COALESCE(a.destination_table, j.destination_table) AS destination_table,
  COALESCE(a.end_time, j.end_time) AS end_time,
  j.edition AS edition, -- this field is only available in information schema
  COALESCE(a.error_result, j.error_result) AS error_result,
  COALESCE(a.job_id, j.job_id) AS job_id,
  j.job_stages AS job_stages, -- this field is only available in the information schema
  COALESCE(a.job_type, j.job_type) AS job_type,
  COALESCE(a.labels, j.labels) AS labels,
  j.parent_job_id AS parent_job_id, -- this field is only available in information schema
  COALESCE(a.priority, j.priority) AS priority,
  COALESCE(a.project_id, j.project_id) AS project_id,
  COALESCE(a.project_number, j.project_number) AS project_number,
  COALESCE(a.query, j.query) AS query,
  COALESCE(a.referenced_tables, j.referenced_tables) AS referenced_tables,
  COALESCE(a.reservation_id, j.reservation_id) AS reservation_id,
  j.session_info AS session_info, -- this field is only available in information schema
  COALESCE(a.start_time, j.start_time) AS start_time,
  COALESCE(a.state, j.state) AS state,
  COALESCE(a.statement_type, j.statement_type) AS statement_type,
  j.timeline AS timeline, -- this field is only available in information schema
  j.total_bytes_billed AS total_bytes_billed, -- this field is only available in information schema
  j.total_bytes_processed AS total_bytes_processed, -- this field is only available in information schema
  COALESCE(a.total_modified_partitions, j.total_modified_partitions) AS total_modified_partitions,
  COALESCE(a.total_slot_ms, j.total_slot_ms) AS total_slot_ms,
  j.transaction_id AS transaction_id, -- this field is only available in information schema
  COALESCE(a.user_email, j.user_email) AS user_email,
  j.query_info AS query_info, -- this field is only available in information schema
  {%- if dbt_bigquery_monitoring_variable_enable_total_services_sku_slot_ms() %}
  j.total_services_sku_slot_ms AS total_services_sku_slot_ms, -- this field is only available in information schema
  {%- endif %}
  {%- if dbt_bigquery_monitoring_variable_enable_principal_subject() %}
  j.principal_subject AS principal_subject, -- this field is only available in information schema
  {%- endif %}
  j.transferred_bytes AS transferred_bytes
  {%- if dbt_bigquery_monitoring_variable_enable_materialized_view_statistics() %},
  j.materialized_view_statistics AS materialized_view_statistics -- this field is only available in information schema
  {%- endif %}
 FROM {{ ref('jobs_from_audit_logs') }} AS a
 LEFT JOIN {{ ref('information_schema_jobs') }} AS j ON
  {% if is_incremental() %}
  j.creation_time BETWEEN TIMESTAMP_SUB(TIMESTAMP_TRUNC(_dbt_max_partition, HOUR), INTERVAL 6 HOUR) AND TIMESTAMP_TRUNC(_dbt_max_partition, HOUR)
  {% else %}
  j.creation_time >= TIMESTAMP_SUB(TIMESTAMP_TRUNC(TIMESTAMP_SUB(
  TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), HOUR),
  INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY), HOUR), INTERVAL 6 HOUR)
  {% endif %}
  AND (a.project_id = j.project_id AND a.job_id = j.job_id)
 WHERE
  {% if is_incremental() %}
  a.timestamp >= TIMESTAMP_TRUNC(_dbt_max_partition, HOUR)
  {% else %}
  a.timestamp >= TIMESTAMP_SUB(
   TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), HOUR),
   INTERVAL {{ dbt_bigquery_monitoring_variable_lookback_window_days() }} DAY)
  {% endif %}
