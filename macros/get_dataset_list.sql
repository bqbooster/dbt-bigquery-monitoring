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

    {% set preflight_sql %}
    SELECT CONCAT('`', CATALOG_NAME, '`.`', SCHEMA_NAME, '`') AS SCHEMA_NAME
    FROM `region-{{ dbt_bigquery_monitoring_variable_bq_region() }}`.`INFORMATION_SCHEMA`.`SCHEMATA`
    {% endset %}
    
    {% set results = run_query(preflight_sql) %}
    {% set dataset_list = results | map(attribute='SCHEMA_NAME') | list %}
    
    {%- if dataset_list | length == 0 -%}
      {{ log("[dbt-bigquery-monitoring] No datasets found in the project list", info=False) }}
    {%- endif -%}
    
    {{ return(dataset_list) }}
  {% else %}
    {{ return([]) }}
  {% endif %}
{% endmacro %}
