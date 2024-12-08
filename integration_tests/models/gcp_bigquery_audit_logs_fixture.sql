{{
   config(
    materialized = "table",
    tags=['fixtures'],
   )
}}

WITH sample_audit_logs AS (
    SELECT
    'projects/my-project/logs/cloudaudit.googleapis.com%2Factivity' AS logName,
    STRUCT(
        STRUCT(
            'my-project' AS project_id,
            'us-central1' AS location,
            'my_dataset' AS dataset_id
        ) AS labels
    ) AS resource,
    STRUCT(
        STRUCT(
            'user@example.com' AS principalEmail
        ) AS authenticationInfo,
        'projects/my-project/logs/cloudaudit.googleapis.com%2Factivity' AS resourceName,
        'google.cloud.bigquery.v2' AS serviceName,
        'jobservice.jobCompleted' AS methodName,
        STRUCT(
            '192.168.1.100' AS callerIp,
            'Mozilla/5.0' AS callerSuppliedUserAgent
        ) AS requestMetadata,
        TO_JSON_STRING(JSON_OBJECT(
            'jobChange', JSON_OBJECT(
                'job', JSON_OBJECT(
                    'jobName', 'projects/my-project/jobs/job_123456789',
                    'jobConfig', JSON_OBJECT(
                        'type', 'QUERY',
                        'queryConfig', JSON_OBJECT(
                            'query', 'SELECT * FROM my_dataset.my_table',
                            'destinationTable', 'my_dataset.output_table',
                            'priority', 'BATCH',
                            'statementType', 'SELECT'
                        )
                    ),
                    'jobStats', JSON_OBJECT(
                        'createTime', '2024-01-15T10:30:40Z',
                        'startTime', '2024-01-15T10:30:41Z',
                        'endTime', '2024-01-15T10:30:44Z',
                        'queryStats', JSON_OBJECT(
                            'cacheHit', 'false',
                            'totalBytesProcessed', '1000000',
                            'outputRowCount', '500',
                            'billingTier', '1',
                            'referencedTables', '["projects/my_project/datasets/my_dataset/tables/my_table"]'
                        ),
                        'totalSlotMs', 3000
                    ),
                    'jobStatus', JSON_OBJECT(
                        'jobState', 'DONE',
                        'errorResult', NULL
                    )
                )
            )
        )) AS metadataJson
    ) AS protopayload_auditlog,
    'Job completed successfully' AS textPayload,
    TIMESTAMP('2024-01-15 10:30:45') AS timestamp,
    TIMESTAMP('2024-01-15 10:30:46') AS receiveTimestamp,
    'INFO' AS severity,
    'op_123456789' AS insertId,
    STRUCT(
        'GET' AS requestMethod,
        'https://bigquery.googleapis.com/bigquery/v2/projects/my-project/jobs/job_123456789' AS requestUrl
    ) AS httpRequest,
    STRUCT(
        'operations/job_123456789' AS id,
        'DONE' AS last
    ) AS operation,
    'projects/my-project/traces/trace123' AS trace,
    'span123' AS spanId,
    TRUE AS traceSampled,
    STRUCT(
        'BigQueryAuditMetadata' AS file,
        'google3/cloud/bigquery/logging/audit_logging.cc' AS function,
        123 AS line
    ) AS sourceLocation,
    NULL AS split,
    [STRUCT('env' AS key, 'prod' AS value)] AS labels,
    NULL AS errorGroups
),
more_sample_audit_logs AS (
    SELECT
    'projects/another-project/logs/cloudaudit.googleapis.com%2Factivity' AS logName,
    STRUCT(
        STRUCT(
            'another-project' AS project_id,
            'europe-west1' AS location,
            'analytics' AS dataset_id
        ) AS labels
    ) AS resource,
    STRUCT(
        STRUCT(
            'admin@company.com' AS principalEmail
        ) AS authenticationInfo,
        'projects/another-project/logs/cloudaudit.googleapis.com%2Factivity' AS resourceName,
        'google.cloud.bigquery.v2' AS serviceName,
        'jobservice.jobCompleted' AS methodName,
        STRUCT(
            '10.0.0.1' AS callerIp,
            'DataStudio/1.0' AS callerSuppliedUserAgent
        ) AS requestMetadata,
        TO_JSON_STRING(JSON_OBJECT(
            'jobChange', JSON_OBJECT(
                'job', JSON_OBJECT(
                    'jobName', 'projects/another-project/jobs/job_987654321',
                    'jobConfig', JSON_OBJECT(
                        'type', 'LOAD',
                        'loadConfig', JSON_OBJECT(
                            'destinationTable', 'analytics.user_data',
                            'createDisposition', 'CREATE_IF_NEEDED',
                            'writeDisposition', 'WRITE_TRUNCATE'
                        )
                    ),
                    'jobStats', JSON_OBJECT(
                        'createTime', '2024-01-16T14:45:20Z',
                        'startTime', '2024-01-16T14:45:21Z',
                        'endTime', '2024-01-16T14:45:22Z',
                        'loadStats', JSON_OBJECT(
                            'totalOutputBytes', '2500000'
                        ),
                        'totalSlotMs', 1500
                    ),
                    'jobStatus', JSON_OBJECT(
                        'jobState', 'DONE',
                        'errorResult', NULL
                    )
                )
            )
        )) AS metadataJson
    ) AS protopayload_auditlog,
    'Load job completed successfully' AS textPayload,
    TIMESTAMP('2024-01-16 14:45:22') AS timestamp,
    TIMESTAMP('2024-01-16 14:45:23') AS receiveTimestamp,
    'INFO' AS severity,
    'op_987654321' AS insertId,
    STRUCT(
        'GET' AS requestMethod,
        'https://bigquery.googleapis.com/bigquery/v2/projects/another-project/jobs/job_987654321' AS requestUrl
    ) AS httpRequest,
    STRUCT(
        'operations/job_987654321' AS id,
        'DONE' AS last
    ) AS operation,
    'projects/another-project/traces/trace456' AS trace,
    'span456' AS spanId,
    TRUE AS traceSampled,
    STRUCT(
        'BigQueryAuditMetadata' AS file,
        'google3/cloud/bigquery/logging/audit_logging.cc' AS function,
        456 AS line
    ) AS sourceLocation,
    NULL AS split,
    [STRUCT('env' AS key, 'staging' AS value)] AS labels,
    NULL AS errorGroups
)

SELECT * FROM sample_audit_logs
UNION ALL
SELECT * FROM more_sample_audit_logs
