{#
  Get a cached list of datasets for INFORMATION_SCHEMA queries.
  
  This macro fetches datasets from INFORMATION_SCHEMA.SCHEMATA and caches the result
  to avoid redundant queries when multiple models need the same data.
  
  Usage:
    {% set dataset_list = get_dataset_list() %}
    
  Returns:
    A list of fully-qualified dataset names like ['`project`.`dataset`', ...]
#}
{% macro validate_input_datasets_identifier_part(part_name, part_value, allowed_chars, allowed_description, dataset) %}
  {% for char in part_value %}
    {% if char not in allowed_chars %}
      {% do exceptions.raise_compiler_error(
        "input_datasets " ~ part_name ~ " identifiers may contain only " ~
        allowed_description ~ ": " ~ dataset
      ) %}
    {% endif %}
  {% endfor %}
{% endmacro %}

{% macro information_schema_project_identifier(project) %}
  {% set cleaned = project | string | trim %}
  {% if cleaned | length == 0 or '`' in cleaned or '\n' in cleaned or '\r' in cleaned or ';' in cleaned %}
    {% do exceptions.raise_compiler_error(
      "input_gcp_projects entries must be project ids without backticks or statement breaks: " ~ cleaned
    ) %}
  {% endif %}
  {{ return(cleaned) }}
{% endmacro %}

{% macro information_schema_region_identifier(region) %}
  {% set cleaned = region | string | trim %}
  {% if cleaned | length == 0 or '`' in cleaned or '\n' in cleaned or '\r' in cleaned or ';' in cleaned or ' ' in cleaned %}
    {% do exceptions.raise_compiler_error(
      "bq_region must be a BigQuery location such as us or europe-west1: " ~ cleaned
    ) %}
  {% endif %}
  {{ return(cleaned) }}
{% endmacro %}

{% macro agate_column_values(table, candidates) %}
  {% for name in candidates %}
    {% if name in table.column_names %}
      {{ return(table.columns[name].values() | list) }}
    {% endif %}
  {% endfor %}
  {% do exceptions.raise_compiler_error(
    "Expected one of " ~ (candidates | join(', ')) ~ " in " ~ (table.column_names | join(', '))
  ) %}
{% endmacro %}

{% macro datasets_from_schemata_columns(schema_names, error_messages) %}
  {% set dataset_list = [] %}
  {% set errors = [] %}
  {% for schema_name in schema_names %}
    {% if schema_name %}
      {% do dataset_list.append(schema_name) %}
    {% endif %}
  {% endfor %}
  {% for error_message in error_messages %}
    {% if error_message %}
      {% do errors.append(error_message) %}
    {% endif %}
  {% endfor %}
  {{ return({'datasets': dataset_list, 'errors': errors}) }}
{% endmacro %}

{% macro raise_if_schemata_discovery_failed(parsed) %}
  {% if parsed['datasets'] | length == 0 and parsed['errors'] | length > 0 %}
    {% do exceptions.raise_compiler_error(
      "[dbt-bigquery-monitoring] Could not list datasets for any input project. " ~ parsed['errors'][0]
    ) %}
  {% endif %}
{% endmacro %}

{% macro information_schema_schemata_lookup_sql() %}
  {% set region = dbt_bigquery_monitoring.information_schema_region_identifier(
    dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_bq_region()
  ) %}
  {% set projects = dbt_bigquery_monitoring.project_list() %}
  {% if projects | length == 0 %}
    {% set sql = "SELECT CONCAT('`', REPLACE(CATALOG_NAME, '`', ''), '`.`', REPLACE(SCHEMA_NAME, '`', ''), '`') AS SCHEMA_NAME\nFROM `region-" ~ region ~ "`.`INFORMATION_SCHEMA`.`SCHEMATA`" %}
  {% else %}
    {# One project's Access Denied must not hide datasets from the others.
       UNION ALL fails the whole discovery query on the first error.
       Script variables avoid INSERT, which the BigQuery sandbox rejects. #}
    {% set statements = [] %}
    {% do statements.append("DECLARE datasets ARRAY<STRING> DEFAULT []") %}
    {% do statements.append("DECLARE errors ARRAY<STRING> DEFAULT []") %}
    {% for project in projects %}
      {% set project_id = dbt_bigquery_monitoring.information_schema_project_identifier(project) %}
      {% set block %}
BEGIN
  SET datasets = ARRAY_CONCAT(
    datasets,
    ARRAY(
      SELECT CONCAT('`', REPLACE(CATALOG_NAME, '`', ''), '`.`', REPLACE(SCHEMA_NAME, '`', ''), '`')
      FROM `{{ project_id }}`.`region-{{ region }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
    )
  );
EXCEPTION WHEN ERROR THEN
  SET errors = ARRAY_CONCAT(errors, [@@error.message]);
END
      {% endset %}
      {% do statements.append(block | trim) %}
    {% endfor %}
    {% set block %}
SELECT dataset AS SCHEMA_NAME, CAST(NULL AS STRING) AS ERROR_MESSAGE
FROM UNNEST(datasets) AS dataset
UNION ALL
SELECT CAST(NULL AS STRING) AS SCHEMA_NAME, error_message AS ERROR_MESSAGE
FROM UNNEST(errors) AS error_message
    {% endset %}
    {% do statements.append(block | trim) %}
    {% set sql = statements | join(';\n') %}
  {% endif %}
  {{ return(sql) }}
{% endmacro %}

{% macro get_dataset_list() %}
  {# Only execute during actual run, not during parsing #}
  {% if execute %}
    {% set raw_input_datasets = dbt_bigquery_monitoring.dbt_bigquery_monitoring_variable_input_datasets() %}
    {% set input_datasets_list = none %}

    {% if raw_input_datasets is string %}
      {% if raw_input_datasets | length > 0 %}
        {% set input_datasets_list = [raw_input_datasets] %}
      {% endif %}
    {% elif raw_input_datasets is sequence and raw_input_datasets is not mapping %}
      {% if raw_input_datasets | length > 0 %}
        {% set input_datasets_list = raw_input_datasets %}
      {% endif %}
    {% else %}
      {% do exceptions.raise_compiler_error(
        "input_datasets must be a string or list of project.dataset values"
      ) %}
    {% endif %}

    {% if input_datasets_list is not none %}
      {% set normalized_input_datasets = [] %}

      {% for dataset in input_datasets_list %}
        {% if dataset is not string %}
          {% do exceptions.raise_compiler_error(
            "input_datasets entries must use project.dataset: " ~ (dataset | tojson)
          ) %}
        {% endif %}

        {% set trimmed_dataset = dataset | trim %}
        {% set dataset_parts = trimmed_dataset.split('.') %}

        {% if dataset_parts | length != 2 or dataset_parts[0] | length == 0 or dataset_parts[1] | length == 0 %}
          {% do exceptions.raise_compiler_error(
            "input_datasets entries must use project.dataset: " ~ trimmed_dataset
          ) %}
        {% endif %}

        {% set project_part = dataset_parts[0] %}
        {% set dataset_part = dataset_parts[1] %}

        {% do dbt_bigquery_monitoring.validate_input_datasets_identifier_part(
          'project',
          project_part,
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-',
          'letters, numbers, underscores, and hyphens',
          trimmed_dataset
        ) %}
        {% do dbt_bigquery_monitoring.validate_input_datasets_identifier_part(
          'dataset',
          dataset_part,
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_',
          'letters, numbers, and underscores',
          trimmed_dataset
        ) %}

        {% do normalized_input_datasets.append(
          '`' ~ project_part ~ '`.`' ~ dataset_part ~ '`'
        ) %}
      {% endfor %}

      {{ return(normalized_input_datasets) }}
    {% endif %}

    {# Project mode must read each input project's SCHEMATA. An unqualified
       region-REGION reference lists the execution project only, so partitions,
       key/constraint usage, and search indexes then query the wrong project. #}
    {% set preflight_sql = dbt_bigquery_monitoring.information_schema_schemata_lookup_sql() %}
    {% set results = run_query(preflight_sql) %}
    {% if results is none %}
      {{ return([]) }}
    {% endif %}

    {% if dbt_bigquery_monitoring.project_list() | length == 0 %}
      {% set dataset_list = results | map(attribute='SCHEMA_NAME') | list %}
    {% else %}
      {% set parsed = dbt_bigquery_monitoring.datasets_from_schemata_columns(
        dbt_bigquery_monitoring.agate_column_values(results, ['SCHEMA_NAME', 'schema_name']),
        dbt_bigquery_monitoring.agate_column_values(results, ['ERROR_MESSAGE', 'error_message'])
      ) %}
      {% for error_message in parsed['errors'] %}
        {{ log("[dbt-bigquery-monitoring] Skipping an input project while listing datasets: " ~ error_message, info=True) }}
      {% endfor %}
      {% do dbt_bigquery_monitoring.raise_if_schemata_discovery_failed(parsed) %}
      {% set dataset_list = parsed['datasets'] %}
    {% endif %}

    {%- if dataset_list | length == 0 -%}
      {{ log("[dbt-bigquery-monitoring] No datasets found in the project list", info=False) }}
    {%- endif -%}

    {{ return(dataset_list) }}
  {% else %}
    {{ return([]) }}
  {% endif %}
{% endmacro %}
