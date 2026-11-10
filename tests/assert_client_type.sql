-- Opt-in client_type labels. The default jobs_with_cost CASE is not this query.
WITH samples AS (
    SELECT *
    FROM UNNEST([
        STRUCT(
            'dbt_invocation' AS scenario,
            'dbt' AS expected,
            [STRUCT('dbt_invocation_id' AS key, 'abc' AS value)] AS labels,
            'person@example.com' AS user_email,
            CAST(NULL AS STRING) AS dbt_info,
            CAST(NULL AS STRING) AS caller_supplied_user_agent,
            CAST(NULL AS STRING) AS principal_subject
        ),
        STRUCT(
            'elementary_before_dbt',
            'Elementary',
            [
                STRUCT('dbt_invocation_id' AS key, 'abc' AS value),
                STRUCT('elementary' AS key, 'true' AS value)
            ],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'airflow_only',
            'Airflow',
            [STRUCT('airflow-dag' AS key, 'nightly' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'dbt_before_airflow',
            'dbt',
            [
                STRUCT('airflow-dag' AS key, 'nightly' AS value),
                STRUCT('dbt_invocation_id' AS key, 'abc' AS value)
            ],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'looker',
            'Looker',
            [STRUCT('looker-query' AS key, 'abc' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'sheets_manual',
            'Google connected sheets - manual',
            [STRUCT('sheets_trigger' AS key, 'user' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'sheets_scheduled',
            'Google connected sheets - scheduled',
            [STRUCT('sheets_trigger' AS key, 'schedule' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'scheduled_query',
            'Scheduled query',
            [STRUCT('data_source_id' AS key, 'scheduled_query' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'hex',
            'Hex',
            [STRUCT('hex_project' AS key, 'proj' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'dataform',
            'Dataform',
            [STRUCT('dataform_workflow' AS key, 'daily' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'dbt_user_agent',
            'dbt',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'dbt-core-1.8',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'fivetran_agent',
            'Fivetran',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'Fivetran/abc',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'rudderstack',
            'Rudderstack',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'rudderstack@example.com',
            CAST(NULL AS STRING),
            'gcloud-golang-bigquery/1',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'golang',
            'Golang Client',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'gcloud-golang/1',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'node_service_account_keeps_client',
            'Node Client',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'etl@proj.iam.gserviceaccount.com',
            CAST(NULL AS STRING),
            'gcloud-node/1',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'python',
            'Python Client',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'gl-python/1',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'gcloud',
            'Google Cloud SDK',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'google-cloud-sdk/1',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'hightouch',
            'Hightouch',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'Hightouch/1',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'web',
            'Web console',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'Mozilla/5.0',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'java',
            'Java Client',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            'SimbaJDBCDriver/1',
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'service_account_email',
            'Service account',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'etl@proj.iam.gserviceaccount.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'service_account_principal',
            'Service account',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            'serviceAccount:etl@proj.iam.gserviceaccount.com'
        ),
        STRUCT(
            'all_null',
            'Unknown',
            CAST(NULL AS ARRAY<STRUCT<key STRING, value STRING>>),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'explicit_client_type',
            'custom-runner',
            [STRUCT('client_type' AS key, 'custom-runner' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'unknown_label_falls_through_to_service_account',
            'Service account',
            [STRUCT('client_type' AS key, 'Unknown' AS value)],
            'etl@proj.iam.gserviceaccount.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'model_label_is_not_mode',
            'Unknown',
            [STRUCT('model' AS key, 'stg_orders' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'mode',
            'Mode',
            [STRUCT('mode_report' AS key, 'revenue' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'tableau',
            'Tableau',
            [STRUCT('tableau-workbook' AS key, 'sales' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'metabase',
            'Metabase',
            [STRUCT('metabase' AS key, 'card' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'prefect',
            'Prefect',
            [STRUCT('prefect_flow' AS key, 'daily' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'dagster',
            'Dagster',
            [STRUCT('dagster_run' AS key, 'abc' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'stitch',
            'Stitch',
            [STRUCT('stitch_client' AS key, 'abc' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'sigma',
            'Sigma',
            [STRUCT('sigma_workbook' AS key, 'abc' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'lightdash',
            'Lightdash',
            [STRUCT('lightdash_user' AS key, 'abc' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'dbt_info_comment',
            'dbt',
            CAST([] AS ARRAY<STRUCT<key STRING, value STRING>>),
            'person@example.com',
            '{"node_id": "model.proj.orders"}',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        ),
        STRUCT(
            'blank_client_type',
            'Unknown',
            [STRUCT('client_type' AS key, '   ' AS value)],
            'person@example.com',
            CAST(NULL AS STRING),
            CAST(NULL AS STRING),
            CAST(NULL AS STRING)
        )
    ])
),

classified AS (
    SELECT
        scenario,
        expected,
        {{ improved_client_type_sql() }} AS actual
    FROM samples
)

SELECT
    scenario,
    expected,
    actual
FROM classified
WHERE actual IS DISTINCT FROM expected
