{% macro dbt_bigquery_monitoring_get_column_selection(region, table_name, columns_to_check) %}
  {%- set selection = [] -%}
  {%- set should_check_columns = execute and flags.WHICH in ['run', 'build', 'test', 'seed', 'snapshot'] -%}
  
  {%- if should_check_columns -%}
    {%- set columns_query -%}
      SELECT column_name
      FROM `region-{{ region }}`.INFORMATION_SCHEMA.COLUMNS
      WHERE table_name = '{{ table_name }}'
    {%- endset -%}
    {%- set results = run_query(columns_query) -%}
    {%- set available_columns = results.columns[0].values() | map('lower') | list -%}
    
    {%- for col_info in columns_to_check -%}
      {%- set col_name = col_info.name -%}
      {%- set col_type = col_info.get('type', 'STRING') -%}
      {%- if col_name | lower in available_columns -%}
        {%- do selection.append(col_name) -%}
      {%- else -%}
        {%- do selection.append("CAST(NULL AS " ~ col_type ~ ") AS " ~ col_name) -%}
      {%- endif -%}
    {%- endfor -%}
  {%- else -%}
    {%- for col_info in columns_to_check -%}
      {%- do selection.append(col_info.name) -%}
    {%- endfor -%}
  {%- endif -%}

  {{ selection | join(',\n') }}
{% endmacro %}
