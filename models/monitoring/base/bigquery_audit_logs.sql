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
FROM {{ ref('bigquery_audit_logs_v2') }}
