{#-
  Opt-in client_type CASE. The historical CASE in jobs_with_cost.sql is the default.
  caller_supplied_user_agent is CAST to STRING so INFORMATION_SCHEMA-only mode
  (untyped NULL) and audit-log mode both compile. principal_subject is referenced
  only when that experimental column is enabled, and it is cast for the same reason.
  Tool checks run before the service-account fallback so a known client that
  authenticates with a service account keeps its client name.
-#}
{% macro improved_client_type_sql() %}
    {% set user_agent = "LOWER(IFNULL(CAST(caller_supplied_user_agent AS STRING), ''))" %}
CASE
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'elementary')
      OR LOWER(IFNULL(label.value, '')) LIKE '%elementary%'
  )
    OR LOWER(IFNULL(JSON_EXTRACT_SCALAR(dbt_info, '$.node_id'), '')) LIKE '%elementary%'
    OR LOWER(IFNULL(user_email, '')) LIKE '%elementary%'
    OR {{ user_agent }} LIKE '%elementary%'
    THEN 'Elementary'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE (
      label.key IN (
        'dbt_invocation_id',
        'dbt_version',
        'dbt_project_name',
        'dbt_cloud_project_id',
        'dbt_cloud_job_id',
        'dbt_node_id'
      )
      AND label.value IS NOT NULL
    )
      OR (
        LOWER(label.key) IN ('app', 'tool', 'client')
        AND LOWER(label.value) IN ('dbt', 'dbt-core', 'dbt cloud', 'dbt_cloud')
      )
  )
    OR IFNULL(LENGTH(dbt_info), 0) > 0
    OR STARTS_WITH({{ user_agent }}, 'dbt')
    THEN 'dbt'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'airflow-')
      OR STARTS_WITH(LOWER(label.key), 'airflow_')
      OR LOWER(label.key) IN ('composer', 'composer-dag', 'composer_dag')
      OR STARTS_WITH(LOWER(IFNULL(label.value, '')), 'airflow')
  )
    OR {{ user_agent }} LIKE '%airflow%'
    OR {{ user_agent }} LIKE '%composer%'
    THEN 'Airflow'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE label.key LIKE 'looker-%' AND label.value IS NOT NULL
  )
    OR {{ user_agent }} LIKE '%looker%'
    THEN 'Looker'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE label.key = 'sheets_trigger' AND label.value = 'user'
  ) THEN 'Google connected sheets - manual'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE label.key = 'sheets_trigger' AND label.value = 'schedule'
  ) THEN 'Google connected sheets - scheduled'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE label.key = 'data_source_id' AND label.value = 'scheduled_query'
  ) THEN 'Scheduled query'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'dataform')
      OR LOWER(IFNULL(label.value, '')) = 'dataform'
  )
    OR {{ user_agent }} LIKE '%dataform%'
    THEN 'Dataform'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'hex_')
      OR STARTS_WITH(LOWER(label.key), 'hex-')
      OR LOWER(label.value) = 'hex'
  )
    OR STARTS_WITH({{ user_agent }}, 'hex')
    THEN 'Hex'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'fivetran')
      OR LOWER(label.value) = 'fivetran'
  )
    OR STARTS_WITH({{ user_agent }}, 'fivetran')
    THEN 'Fivetran'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'hightouch')
      OR LOWER(label.value) = 'hightouch'
  )
    OR STARTS_WITH({{ user_agent }}, 'hightouch')
    THEN 'Hightouch'
  WHEN {{ user_agent }} LIKE 'gcloud-golang-bigquery%'
    AND LOWER(IFNULL(user_email, '')) LIKE 'rudderstack%'
    THEN 'Rudderstack'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'tableau')
      OR LOWER(label.value) = 'tableau'
  )
    OR {{ user_agent }} LIKE '%tableau%'
    THEN 'Tableau'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'metabase')
      OR LOWER(label.value) = 'metabase'
  )
    OR {{ user_agent }} LIKE '%metabase%'
    THEN 'Metabase'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'mode_')
      OR LOWER(label.key) IN ('mode', 'mode-report', 'mode_report')
      OR LOWER(IFNULL(label.value, '')) IN ('mode', 'modeanalytics')
      OR LOWER(IFNULL(label.value, '')) LIKE '%modeanalytics%'
  )
    OR {{ user_agent }} LIKE '%modeanalytics%'
    THEN 'Mode'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'sigma_')
      OR STARTS_WITH(LOWER(label.key), 'sigma-')
      OR LOWER(label.value) = 'sigma'
  )
    OR {{ user_agent }} LIKE '%sigmacomputing%'
    THEN 'Sigma'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'lightdash')
      OR LOWER(label.value) = 'lightdash'
  )
    OR {{ user_agent }} LIKE '%lightdash%'
    THEN 'Lightdash'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'prefect')
      OR LOWER(label.value) = 'prefect'
  )
    OR {{ user_agent }} LIKE '%prefect%'
    THEN 'Prefect'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'dagster')
      OR LOWER(label.value) = 'dagster'
  )
    OR {{ user_agent }} LIKE '%dagster%'
    THEN 'Dagster'
  WHEN EXISTS (
    SELECT 1 FROM UNNEST(labels) AS label
    WHERE STARTS_WITH(LOWER(label.key), 'stitch')
      OR LOWER(label.value) = 'stitch'
  )
    OR {{ user_agent }} LIKE '%stitchdata%'
    THEN 'Stitch'
  WHEN EXISTS (
    SELECT 1
    FROM UNNEST(labels) AS label
    WHERE label.key = 'client_type'
      AND NULLIF(TRIM(label.value), '') IS NOT NULL
      AND LOWER(label.value) != 'unknown'
  ) THEN (
    SELECT label.value
    FROM UNNEST(labels) AS label
    WHERE label.key = 'client_type'
      AND NULLIF(TRIM(label.value), '') IS NOT NULL
      AND LOWER(label.value) != 'unknown'
    ORDER BY label.value
    LIMIT 1
  )
  WHEN {{ user_agent }} LIKE 'gcloud-golang%' OR {{ user_agent }} LIKE 'google-api-go%' THEN 'Golang Client'
  WHEN STARTS_WITH({{ user_agent }}, 'gcloud-node') THEN 'Node Client'
  WHEN STARTS_WITH({{ user_agent }}, 'gl-python') THEN 'Python Client'
  WHEN STARTS_WITH({{ user_agent }}, 'google-cloud-sdk') THEN 'Google Cloud SDK'
  WHEN STARTS_WITH({{ user_agent }}, 'mozilla') THEN 'Web console'
  WHEN STARTS_WITH({{ user_agent }}, 'simbajdbcdriver') THEN 'Java Client'
  WHEN ENDS_WITH(LOWER(IFNULL(user_email, '')), '.iam.gserviceaccount.com') THEN 'Service account'
  {%- if dbt_bigquery_monitoring_variable_enable_principal_subject() %}
  WHEN LOWER(CAST(principal_subject AS STRING)) LIKE '%serviceaccount%' THEN 'Service account'
  {%- endif %}
  ELSE COALESCE(CAST(caller_supplied_user_agent AS STRING), 'Unknown')
END
{% endmacro %}
