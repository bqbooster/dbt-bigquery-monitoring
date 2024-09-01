import pytest
from bs4 import BeautifulSoup
from documentation_parser import parse_required_role, parse_table_name, update_column_list
from sql_generator import generate_sql

def test_parse_required_role():
    # Test case: Required role is present
    with open("html_content.html", "r") as file:
      html_content = file.read()
    soup = BeautifulSoup(html_content, "html.parser")
    result = parse_required_role(soup)
    expected = 'To query the INFORMATION_SCHEMA.OBJECT_PRIVILEGES view, you need following\nIdentity and Access Management (IAM) permissions:\nbigquery.datasets.get for datasets.\nbigquery.tables.getIamPolicy for tables and views.\nFor more information about BigQuery permissions, see\nAccess control with IAM.'
    assert result == expected

    # Test case: Required role is present (second case)
    with open("html_content_2.html", "r") as file:
      html_content = file.read()
    soup = BeautifulSoup(html_content, "html.parser")
    result = parse_required_role(soup)
    expected = '\n\n    To get the permission that you need to query the INFORMATION_SCHEMA.JOBS view,\n\n    ask your administrator to grant you the\n\n\nBigQuery Resource Viewer  (roles/bigquery.resourceViewer) IAM role on your project.\n\n\n\n\nFor more information about granting roles, see Manage access.\n\n\n\n      This predefined role contains the\n       bigquery.jobs.listAll permission, which is\n        required to query the INFORMATION_SCHEMA.JOBS view.\n\n\n\n  \n    You might also be able to get\n      this permission\n    with custom roles or\n    other predefined roles.\n  For more information about BigQuery permissions, see\nAccess control with IAM.'
    assert result == expected

    # Test case: Required role is not present
    html_content = """
    <h2 id="other_role" data-text="Other role" tabindex="-1" role="presentation">
        <span class="devsite-heading" role="heading" aria-level="2">Other role</span>
        <button type="button" class="devsite-heading-link button-flat material-icons" aria-label="Copy link to this section: Other role" data-title="Copy link to this section: Other role" data-id="other_role"></button>
    </h2>
    <p>
        This is some other role.
    </p>
    """
    soup = BeautifulSoup(html_content, "html.parser")
    assert parse_required_role(soup) is None

def test_parse_table_name():
  # Test case: Table name is present
  with open("html_content.html", "r") as file:
    html_content = file.read()
  soup = BeautifulSoup(html_content, "html.parser")
  result = parse_table_name(soup)
  expected = 'OBJECT_PRIVILEGES'
  assert result == expected

  # Test case: Table name is not present
  html_content = """
  <td>
    <code>RANDOM_STRING.COLUMNS</code>
  </td>
  """
  soup = BeautifulSoup(html_content, "html.parser")
  result = parse_table_name(soup)
  assert result is None


def test_update_column_list():
    # Test case: Columns with exclude_columns
    columns = [
        {"name": "column1", "type": "STRING", "description": "Column 1"},
        {"name": "column2", "type": "INTEGER", "description": "Column 2"},
        {"name": "column3.subcolumn1", "type": "STRING", "description": "Subcolumn 1 of Column 3"},
        {"name": "column3.subcolumn2", "type": "INTEGER", "description": "Subcolumn 2 of Column 3"},
    ]
    exclude_columns = ["column2", "column3.subcolumn1"]
    result = update_column_list(columns, exclude_columns)
    expected_columns = [
        {"name": "column1", "type": "STRING", "description": "Column 1"},
        {'name': 'column3', 'type': 'RECORD', 'description': 'column3.subcolumn1 : Subcolumn 1 of Column 3\ncolumn3.subcolumn2 : Subcolumn 2 of Column 3'},
    ]
    assert result == expected_columns

    # Test case: Columns without exclude_columns
    columns = [
        {"name": "column1", "type": "STRING", "description": "Column 1"},
        {"name": "column2", "type": "INTEGER", "description": "Column 2"},
        {"name": "column3.subcolumn1", "type": "STRING", "description": "Subcolumn 1 of Column 3"},
        {"name": "column3.subcolumn2", "type": "INTEGER", "description": "Subcolumn 2 of Column 3"},
    ]
    exclude_columns = []
    result = update_column_list(columns, exclude_columns)
    expected_columns = [
        {"name": "column1", "type": "STRING", "description": "Column 1"},
        {"name": "column2", "type": "INTEGER", "description": "Column 2"},
        {'name': 'column3', 'type': 'RECORD', 'description': 'column3.subcolumn1 : Subcolumn 1 of Column 3\ncolumn3.subcolumn2 : Subcolumn 2 of Column 3'},
    ]
    assert result == expected_columns

    # Test case: Columns with exclude_columns (second case)
    columns = [
        {"name": "column1", "type": "STRING", "description": "Column 1"},
        {"name": "column2", "type": "INTEGER", "description": "Column 2"},
        {"name": "column3.subcolumn1", "type": "STRING", "description": "Subcolumn 1 of Column 3"},
        {"name": "column3.subcolumn2", "type": "INTEGER", "description": "Subcolumn 2 of Column 3"},
    ]
    exclude_columns = ["column1", "column2"]
    result = update_column_list(columns, exclude_columns)
    expected_columns = [
        {'name': 'column3', 'type': 'RECORD', 'description': 'column3.subcolumn1 : Subcolumn 1 of Column 3\ncolumn3.subcolumn2 : Subcolumn 2 of Column 3'},
    ]
    assert result == expected_columns

def test_generate_sql_table():
    # Test generate_sql function
    columns = [{"name": "field1", "type": "STRING", "description": "Field 1"}, {"name": "field2", "type": "INTEGER", "description": "Field 2"}, {"name": "field3", "type": "STRING", "description": "Field 3"}]
    result = generate_sql("https://cloud.google.com/bigquery/docs/information-schema-jobs", columns, "jobs", "jobs.admin", "table")
    expected = "\n      {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs -#}\n      jobs.admin\n      WITH base AS (\n      {% if project_list()|length > 0 -%}\n          {% for project in project_list() -%}\n            SELECT field1, field2, field3\n            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`jobs`\n          {% if not loop.last %}UNION ALL{% endif %}\n          {% endfor %}\n      {%- else %}\n          SELECT field1, field2, field3\n          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`jobs`\n      {%- endif %}\n      )\n      SELECT\n      field1, field2, field3,\n      FROM\n      base\n      "
    assert result == expected

def test_generate_sql_dataset():
    # Test generate_sql function
    columns = [{"name": "field1", "type": "STRING", "description": "Field 1"}, {"name": "field2", "type": "INTEGER", "description": "Field 2"}, {"name": "field3", "type": "STRING", "description": "Field 3"}]
    result = generate_sql("https://cloud.google.com/bigquery/docs/information-schema-jobs", columns, "jobs", "jobs.admin", "dataset")
    expected = '\n    {# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-jobs -#}\n    jobs.admin\n    \n    {% set preflight_sql -%}\n    {% if project_list()|length > 0 -%}\n    {% for project in project_list() -%}\n    SELECT\n    SCHEMA_NAME\n    FROM `{{ project | trim }}`.`region-{{ var(\'bq_region\') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`\n    {% if not loop.last %}UNION ALL{% endif %}\n    {% endfor %}\n    {%- else %}\n    SELECT\n    SCHEMA_NAME\n    FROM `region-{{ var(\'bq_region\') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`\n    {%- endif %}\n    {%- endset %}\n    {% set results = run_query(preflight_sql) %}\n    {% set dataset_list = results | map(attribute=\'SCHEMA_NAME\') | list %}\n    {%- if dataset_list | length == 0 -%}\n    {{ log("No datasets found in the project list", info=True) }}\n    {%- endif -%}\n    \n    WITH base AS (\n    {%- if dataset_list | length == 0 -%}\n      SELECT CAST(NULL AS STRING) AS field1, CAST(NULL AS INTEGER) AS field2, CAST(NULL AS STRING) AS field3\n      LIMIT 0\n    {%- else %}\n    {% for dataset in dataset_list -%}\n      SELECT field1, field2, field3\n      FROM `{{ dataset | trim }}`.`INFORMATION_SCHEMA`.`jobs`\n    {% if not loop.last %}UNION ALL{% endif %}\n    {% endfor %}\n    {%- endif -%}\n    )\n    SELECT\n    field1, field2, field3,\n    FROM\n    base\n    '
    assert result == expected
