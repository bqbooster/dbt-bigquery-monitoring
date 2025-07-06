{{
   config(
    materialized = "ephemeral",
    enabled = dbt_bigquery_monitoring_variable_enable_gcp_bigquery_audit_logs()
    )
}}
SELECT
  logName,
  resource,
  protopayload_auditlog,
  textPayload,
  timestamp,
  receiveTimestamp,
  severity,
  insertId,
  httpRequest,
  operation,
  trace,
  spanId,
  traceSampled,
  sourceLocation,
  split,
  labels,
  errorGroups
FROM
 `{{ dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_storage_project() }}.{{ dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_dataset() }}.{{ dbt_bigquery_monitoring_variable_gcp_bigquery_audit_logs_table() }}`
