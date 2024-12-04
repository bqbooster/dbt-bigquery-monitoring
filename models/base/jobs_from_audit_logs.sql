{{
   config(
    materialized = "ephemeral",
    enabled = enable_gcp_bigquery_audit_logs()
    )
}}
SELECT
    -- bi_engine_statistics is not available in the audit logs, so we default to NULL
    CAST(NULL AS STRUCT<bi_engine_mode STRING, acceleration_mode STRING, bi_engine_reasons STRUCT<code STRING, message STRING>>) AS bi_engine_statistics,
    CAST(JSON_VALUE(protopayload_auditlog.metadataJson,
            '$.jobChange.job.jobStats.queryStats.cacheHit') AS BOOL) AS cache_hit,
    TIMESTAMP(JSON_VALUE(protopayload_auditlog.metadataJson,
            '$.jobChange.job.jobStats.createTime')) AS creation_time,
    COALESCE(JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.destinationTable'),
        JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.loadConfig.destinationTable')
    ) AS destination_table,
    TIMESTAMP(JSON_VALUE(protopayload_auditlog.metadataJson,
            '$.jobChange.job.jobStats.endTime')) AS end_time,
    STRUCT(
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStatus.errorResult.code') AS code,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStatus.errorResult.message') AS message
    ) as error_result,
    SPLIT(
        JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobName'), '/'
    )[SAFE_OFFSET(3)] AS job_id,
    JSON_QUERY(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.stages') AS job_stages,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.type') AS job_type,
    ARRAY(
    SELECT
      STRUCT(
        key as key,
        value as value
      )
    FROM
      UNNEST((
        SELECT
          ARRAY(
            SELECT AS STRUCT
              REGEXP_EXTRACT(kv, r'"([^"]+)":') as key,
              REGEXP_EXTRACT(kv, r':"([^"]+)"') as value
            FROM
              UNNEST(SPLIT(REGEXP_REPLACE(JSON_QUERY(protopayload_auditlog.metadataJson, '$.labels'), r'[{}]', ''), ',')) kv
          )
      ))
  ) AS labels,
    -- parent_job_id is not available in the audit logs, so we default to NULL
    NULL AS parent_job_id,
    JSON_VALUE(protopayload_auditlog.metadataJson,
        '$.jobChange.job.jobConfig.queryConfig.priority') AS priority,
    resource.labels.project_id,
    -- project_number is not available in the audit logs, so we default to NULL
    NULL AS project_number,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.query') AS query,
    SPLIT(
        JSON_QUERY(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.queryStats.referencedTables'),
        '","'
    ) AS referenced_tables,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.reservation') AS reservation_id,
    TIMESTAMP(JSON_VALUE(protopayload_auditlog.metadataJson,
            '$.jobChange.job.jobStats.startTime')) AS start_time,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStatus.jobState') AS state,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.statementType') AS statement_type,
    JSON_QUERY(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.timeline') AS timeline,
    -- total_bytes_billed is not available in the audit logs, so we default to NULL
    NULL AS total_bytes_billed,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.queryStats.totalBytesProcessed') AS total_bytes_processed,
    -- total_modified_partitions is not available in the audit logs, so we default to NULL
    NULL AS total_modified_partitions,
    CAST(JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.totalSlotMs') AS INT64) AS total_slot_ms,
    -- transaction_id is not available in the audit logs, so we default to NULL
    NULL AS transaction_id,
    protopayload_auditlog.authenticationInfo.principalEmail AS user_email,
    -- query_info is not available in the audit logs, so we default to NULL
    NULL AS query_info,
    -- transferred_bytes is not available in the audit logs, so we default to NULL
    NULL AS transferred_bytes,
    -- materialized_view_statistics is not available in the audit logs, so we default to NULL
    NULL AS materialized_view_statistics,

    protopayload_auditlog.requestMetadata.callerIp AS caller_ip_address,
    protopayload_auditlog.requestMetadata.callerSuppliedUserAgent AS caller_supplied_user_agent,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.type') AS config_type,
    JSON_QUERY(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.labels') AS config_labels,
    COALESCE(JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.createDisposition'),
        JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.loadConfig.createDisposition'))
    AS create_disposition,
    resource.labels.dataset_id AS dataset_id,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.defaultDataset') AS default_dataset,
    CAST(JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.queryTruncated') AS BOOL) AS is_query_truncated,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStatus.jobState') AS job_state,
    resource.labels.location AS location,
    protopayload_auditlog.methodName AS method_name,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.queryStats.outputRowCount') AS output_row_count,
    protopayload_auditlog.metadataJson AS protopayload_auditlog_metadata_json,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.query') AS query_statement,
    SPLIT(TRIM(TRIM(JSON_QUERY(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.queryStats.referencedViews'), '["'), '"]'), '","') AS referenced_views,
    protopayload_auditlog.resourceName AS resource_name,
    protopayload_auditlog.serviceName AS service_name,
    timestamp,
    JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.queryStats.billingTier') AS billing_tier,
    CAST(JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.queryStats.totalBilledBytes') AS INT64) AS total_billed_bytes,
    CAST(JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobStats.loadStats.totalOutputBytes') AS INT64) AS total_output_bytes,
    COALESCE(
      JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.queryConfig.writeDisposition'),
      JSON_VALUE(protopayload_auditlog.metadataJson, '$.jobChange.job.jobConfig.loadConfig.writeDisposition')
      ) AS write_disposition
FROM {{ ref('bigquery_audit_logs') }}
-- Only rows where the jobChange field is not null have metadataJson that contains job information
WHERE JSON_QUERY(protopayload_auditlog.metadataJson, '$.jobChange') IS NOT NULL
