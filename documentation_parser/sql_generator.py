from typing import List

def generate_sql_for_dataset(url: str, columns: List[dict], table_name: str, required_role_str: str):
    # Prepare a run_query statement to fetch datasets for the list of projects
    preflight_sql = f"""
    {{% set preflight_sql -%}}
    {{% if project_list()|length > 0 -%}}
    {{% for project in project_list() -%}}
    SELECT
    SCHEMA_NAME
    FROM `{{{{ project | trim }}}}`.`region-{{{{ var('bq_region') }}}}`.`INFORMATION_SCHEMA`.`SCHEMATA`
    {{% if not loop.last %}}UNION ALL{{% endif %}}
    {{% endfor %}}
    {{%- else %}}
    SELECT
    SCHEMA_NAME
    FROM `region-{{{{ var('bq_region') }}}}`.`INFORMATION_SCHEMA`.`SCHEMATA`
    {{%- endif %}}
    {{%- endset %}}
    {{% set results = run_query(preflight_sql) %}}
    {{% set dataset_list = results | map(attribute='SCHEMA_NAME') | list %}}
    {{%- if dataset_list | length == 0 -%}}
    {{{{ log("No datasets found in the project list", info=True) }}}}
    {{%- endif -%}}
    """

    # Prepare the column names as a comma-separated string
    column_names = [column["name"].lower() for column in columns]
    columns_str = ", ".join(column_names)

    # Generate a SQL for fallback in case of no datasets
    columns_with_empty_values_arr = [f"CAST(NULL AS {column['type']}) AS {column['name'].lower()}" for column in columns]
    columns_with_empty_values_str = ", ".join(columns_with_empty_values_arr)

    sql = f"""
    {{# More details about base table in {url} -#}}
    {required_role_str}
    {preflight_sql}
    WITH base AS (
    {{%- if dataset_list | length == 0 -%}}
      SELECT {columns_with_empty_values_str}
      LIMIT 0
    {{%- else %}}
    {{% for dataset in dataset_list -%}}
      SELECT {columns_str}
      FROM `{{{{ dataset | trim }}}}`.`INFORMATION_SCHEMA`.`{table_name}`
    {{% if not loop.last %}}UNION ALL{{% endif %}}
    {{% endfor %}}
    {{%- endif -%}}
    )
    SELECT
    {columns_str},
    FROM
    base
    """

    return sql

def generate_sql_for_table(url: str, columns: List[dict], table_name: str, required_role_str: str):

    # Prepare the column names as a comma-separated string
    column_names = [column["name"].lower() for column in columns]
    columns_str = ", ".join(column_names)

    # Combine everything into the final SQL string
    sql = f"""
      {{# More details about base table in {url} -#}}
      {required_role_str}
      WITH base AS (
      {{% if project_list()|length > 0 -%}}
          {{% for project in project_list() -%}}
            SELECT {columns_str}
            FROM `{{{{ project | trim }}}}`.`region-{{{{ var('bq_region') }}}}`.`INFORMATION_SCHEMA`.`{table_name}`
          {{% if not loop.last %}}UNION ALL{{% endif %}}
          {{% endfor %}}
      {{%- else %}}
          SELECT {columns_str}
          FROM `region-{{{{ var('bq_region') }}}}`.`INFORMATION_SCHEMA`.`{table_name}`
      {{%- endif %}}
      )
      SELECT
      {columns_str},
      FROM
      base
      """
    return sql


def generate_sql(url: str, columns: List[dict], table_name: str, required_role_str: str, type: str):
    if type == "table":
        return generate_sql_for_table(url, columns, table_name, required_role_str)
    elif type == "dataset":
        return generate_sql_for_dataset(url, columns, table_name, required_role_str)
    else:
        raise ValueError(f"Invalid type: {type}")
