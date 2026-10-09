{#
  INFORMATION_SCHEMA.PARTITIONS cannot scan more than 1000 tables in one query:
  https://docs.cloud.google.com/bigquery/docs/information-schema-partitions

  Small datasets keep a single unfiltered SELECT. Datasets above the batch size
  are queried as separate jobs with `WHERE table_name IN UNNEST([...])`.
  Batches from the same dataset are never UNION ALL'd into one statement, because
  that is still one query against PARTITIONS.
#}

{% macro information_schema_partitions_materialization() %}
  {% set requested = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_google_information_schema_model_materialization() %}
  {# Views and ephemeral models are a single query, so they cannot split a
     oversized dataset into multiple PARTITIONS jobs. CI uses
     project_by_project_view against small datasets. #}
  {% if requested in ['ephemeral', 'view', 'project_by_project_view'] %}
    {{ return(requested) }}
  {% else %}
    {{ return('information_schema_batched_table') }}
  {% endif %}
{% endmacro %}

{% macro information_schema_partitions_empty_sql() %}
  SELECT CAST(NULL AS STRING) AS table_catalog, CAST(NULL AS STRING) AS table_schema, CAST(NULL AS STRING) AS table_name, CAST(NULL AS STRING) AS partition_id, CAST(NULL AS INTEGER) AS total_rows, CAST(NULL AS INTEGER) AS total_logical_bytes, CAST(NULL AS INTEGER) AS total_billable_bytes, CAST(NULL AS TIMESTAMP) AS last_modified_time, CAST(NULL AS STRING) AS storage_tier
  LIMIT 0
{% endmacro %}

{% macro sql_quote_string(value) %}
  {{ return("'" ~ (value | string | replace("'", "''")) ~ "'") }}
{% endmacro %}

{% macro sql_string_list_literal(values) %}
  {% set quoted = [] %}
  {% for value in values %}
    {% do quoted.append(dbt_bigquery_monitoring.sql_quote_string(value)) %}
  {% endfor %}
  {{ return('[' ~ (quoted | join(', ')) ~ ']') }}
{% endmacro %}

{% macro information_schema_partitions_select_sql(dataset, table_names=none) %}
  {% set select_sql %}
SELECT
table_catalog,
table_schema,
table_name,
partition_id,
total_rows,
total_logical_bytes,
total_billable_bytes,
last_modified_time,
storage_tier
FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`PARTITIONS`
{%- if table_names is not none %}
WHERE table_name IN UNNEST({{ dbt_bigquery_monitoring.sql_string_list_literal(table_names) }})
{%- endif %}
  {% endset %}
  {{ return(select_sql | trim) }}
{% endmacro %}

{% macro information_schema_partitions_jobs_for_dataset(dataset, table_names, batch_size) %}
  {% set names = table_names | list %}
  {% set batch_size_n = batch_size | int %}
  {% if names | length == 0 %}
    {{ return([]) }}
  {% elif names | length <= batch_size_n %}
    {{ return([dbt_bigquery_monitoring.information_schema_partitions_select_sql(dataset)]) }}
  {% else %}
    {% set jobs = [] %}
    {% for chunk in dbt_bigquery_monitoring.chunk_list(names, batch_size_n) %}
      {% do jobs.append(dbt_bigquery_monitoring.information_schema_partitions_select_sql(dataset, chunk)) %}
    {% endfor %}
    {{ return(jobs) }}
  {% endif %}
{% endmacro %}

{% macro get_dataset_table_count(dataset) %}
  {% if not execute %}
    {{ return(0) }}
  {% endif %}
  {% set count_sql %}
    SELECT COUNT(*) AS table_count
    FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`TABLES`
  {% endset %}
  {% set results = run_query(count_sql) %}
  {% if results is none or results | length == 0 %}
    {{ return(0) }}
  {% endif %}
  {{ return(results.columns[0].values()[0] | int) }}
{% endmacro %}

{% macro get_dataset_table_names(dataset) %}
  {% if not execute %}
    {{ return([]) }}
  {% endif %}
  {% set names_sql %}
    SELECT table_name
    FROM {{ dataset | trim }}.`INFORMATION_SCHEMA`.`TABLES`
    ORDER BY table_name
  {% endset %}
  {% set results = run_query(names_sql) %}
  {{ return(results | map(attribute='table_name') | list) }}
{% endmacro %}

{% macro information_schema_partitions_job_sqls(dataset_list=none, batch_size=none) %}
  {% if not execute %}
    {{ return([]) }}
  {% endif %}

  {% if dataset_list is none %}
    {% set dataset_list = dbt_bigquery_monitoring.get_dataset_list() %}
  {% endif %}
  {% if batch_size is none %}
    {% set batch_size = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_partitions_table_batch_size() %}
  {% endif %}

  {% set small_sqls = [] %}
  {% set batched_sqls = [] %}

  {% for dataset in dataset_list %}
    {% set table_count = dbt_bigquery_monitoring.get_dataset_table_count(dataset) %}
    {% if table_count == 0 %}
      {{ log("[dbt-bigquery-monitoring] Skipping empty dataset " ~ dataset ~ " for INFORMATION_SCHEMA.PARTITIONS", info=False) }}
    {% elif table_count <= batch_size %}
      {% do small_sqls.append(dbt_bigquery_monitoring.information_schema_partitions_select_sql(dataset)) %}
    {% else %}
      {{ log("[dbt-bigquery-monitoring] Dataset " ~ dataset ~ " has " ~ table_count ~ " tables; querying INFORMATION_SCHEMA.PARTITIONS in batches of " ~ batch_size, info=True) }}
      {% set table_names = dbt_bigquery_monitoring.get_dataset_table_names(dataset) %}
      {% for job_sql in dbt_bigquery_monitoring.information_schema_partitions_jobs_for_dataset(dataset, table_names, batch_size) %}
        {% do batched_sqls.append(job_sql) %}
      {% endfor %}
    {% endif %}
  {% endfor %}

  {% set jobs = [] %}
  {% if small_sqls | length > 0 %}
    {% do jobs.append(small_sqls | join('\nUNION ALL\n')) %}
  {% endif %}
  {% for batched_sql in batched_sqls %}
    {% do jobs.append(batched_sql) %}
  {% endfor %}
  {{ return(jobs) }}
{% endmacro %}
