{{
   config(
    materialized = "ephemeral",
    enabled = enable_gcp_bigquery_audit_logs()
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
 `{{ var('gcp_bigquery_audit_logs_storage_project') }}.{{ var('gcp_bigquery_audit_logs_dataset') }}.{{ var('gcp_bigquery_audit_logs_table') }}`
