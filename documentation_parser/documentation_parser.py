import os
import re
import sys
from typing import List
import yaml
import requests
from bs4 import BeautifulSoup
from config import pages_to_process


def parse_table_name(soup):
    table_name = None
    for td_tag in soup.find_all("td"):
        # Extract the text within the <code> tag
        if td_tag and td_tag.code:
            code_text = td_tag.code.text
        else:
            code_text = None
        if code_text is not None and "INFORMATION_SCHEMA" in code_text:
            # Use regular expression to extract the table name
            match = re.search(r"INFORMATION_SCHEMA\.(\w+)", code_text)
            if match:
                table_name = match.group(1)
            else:
                table_name = None
    return table_name


def parse_required_role(soup):
    required_role = None
    for h2_tag in soup.find_all("h2"):
        if (
            h2_tag.get("data-text") == "Required permissions"
            or h2_tag.get("data-text") == "Required role"
        ):
            required_role = ""
            next_element = h2_tag.find_next_sibling()
            while (
                next_element
                and next_element.name != "h2"
                and not next_element.find("h2")
            ):
                required_role += next_element.text
                next_element = next_element.find_next_sibling()
            break
    return required_role


def update_column_list(input_columns: List[dict], exclude_columns: List[str]):
    # Remove the columns that are in the exclude_columns list
    columns = [
        column
        for column in input_columns
        if column["name"].lower() not in (exclude_columns or [])
    ]

    # Extract all columns that are structures (as containing ".") and remove them from the columns list
    struct_columns = [column for column in input_columns if "." in column["name"]]

    # Remove the struct columns from the columns list
    columns = [column for column in columns if column not in struct_columns]

    # Extract the top level struct columns and deduplicate them
    struct_column_names = set(
        [column["name"].split(".")[0] for column in struct_columns]
    )

    # Create a new column for each struct column and concatenate the description of its children columns
    for struct_column_name in struct_column_names:
        struct_column_description = ""
        for struct_column in struct_columns:
            if struct_column["name"].startswith(struct_column_name):
                struct_column_description += (
                    struct_column["name"] + " : " + struct_column["description"] + "\n"
                )
        columns.append(
            {
                "name": struct_column_name,
                "type": "RECORD",
                "description": struct_column_description.strip(),
            }
        )

    return columns

def generate_sql(url: str, column_names: List[str], table_name: str, required_role_str: str):
    # Prepare the column names as a comma-separated string
    columns_str = ", ".join(column_names)

    # Prepare the base SQL string for the project list
    project_sql = f"""
    SELECT {columns_str}
    FROM `{{{{ project | trim }}}}`.`region-{{{{ var('bq_region') }}}}`.`INFORMATION_SCHEMA`.`{table_name}`
    """

    # Prepare the base SQL string for when there's no project list
    no_project_sql = f"""
    SELECT {columns_str}
    FROM `region-{{{{ var('bq_region') }}}}`.`INFORMATION_SCHEMA`.`{table_name}`
    """

    # Combine everything into the final SQL string
    sql = f"""
    {{# More details about base table in {url} -#}}
    {required_role_str}
    WITH base AS (
    {{% if project_list()|length > 0 -%}}
        {{% for project in project_list() -%}}
        {project_sql}
        {{% if not loop.last %}}UNION ALL{{% endif %}}
        {{% endfor %}}
    {{%- else %}}
        {no_project_sql}
    {{%- endif %}}
    )
    SELECT
    {columns_str},
    FROM
    base
    """
    return sql

def generate_files(
    filename: str, dir: str, url: str, exclude_columns: List[str], override_table_name: str = None
):
    # Fetch the HTML content from the URL
    response = requests.get(url)
    html_content = response.text

    # Parse the HTML content using BeautifulSoup
    soup = BeautifulSoup(html_content, "html.parser")

    # Write the HTML content to a file
    with open("tmp_html_content.html", "w") as f:
        f.write(html_content)

    # Extract the table name from the paragraph
    table_name = None

    # Extract the table name from the table
    if override_table_name:
        table_name = override_table_name
    else:
        table_name = parse_table_name(soup)

    if not table_name:
        print(f"Error: Could not find the table name for url {url}.")
        return

    print(f"Table Name: {table_name}")

    # Extract the required role from following HTML snippet
    required_role = parse_required_role(soup)

    # Extract the table with column information
    table = soup.find("table", {"class": None})

    # Extract the column information from the table
    columns = []
    for row in table.find_all("tr")[1:]:
        cols = row.find_all("td")
        column_info = {
            "name": cols[0].text.strip().replace("\n", "").replace("_<wbr>", "_"),
            "type": cols[1].text.strip(),
            "description": cols[2].text.strip(),
        }
        columns.append(column_info)

    # Update the column list
    columns = update_column_list(columns, exclude_columns)

    base_filename = f"output/{dir}/information_schema_{filename}"

    # Create the YML file
    filename_yml = f"{base_filename}.yml"

    # Create the directory to at the path from filename_yml if it doesn't exist
    directory = os.path.dirname(filename_yml)
    if not os.path.exists(directory):
        os.makedirs(directory)

    # Create the YML file
    with open(filename_yml, "w") as f:
        yaml_data = {
            "version": 2,
            "models": [
                {
                    "name": "information_schema_" + table_name.lower(),
                    "description": "dataset details with related information",
                    "columns": [
                        {
                            "name": column["name"],
                            "description": column["description"],
                            "type": column["type"],
                        }
                        for column in columns
                    ],
                }
            ],
        }
        yaml.dump(yaml_data, f)

    filename_sql = f"{base_filename}.sql"

    # Create the directory to at the path from filename_yml if it doesn't exist
    directory = os.path.dirname(filename_sql)
    if not os.path.exists(directory):
        os.makedirs(directory)

    required_role_str = (
        f"{{# Required role/permissions: {required_role} -#}}\n"
        if required_role
        else ""
    )

    # Create the SQL file
    with open(filename_sql, "w") as f:
        column_names = [column["name"].lower() for column in columns]
        f.write(generate_sql(url, column_names, table_name, required_role_str))

    print(f"Files '{filename_sql}' and '{filename_yml}' have been created.")


def generate_all():
    for filename, target in pages_to_process.items():
        generate_files(
            filename,
            target["dir"],
            target["url"],
            target.get("exclude_columns"),
            target.get("override_table_name"),
        )


def generate_for_key(key: str):
    if key in pages_to_process:
        target = pages_to_process[key]
        generate_files(
            key,
            target["dir"],
            target["url"],
            target.get("exclude_columns"),
            target.get("override_table_name"),
        )
    else:
        print(f"Error: Could not find key {key} in the pages_to_process dictionary.")


if __name__ == "__main__":
    if len(sys.argv) == 2:
        print("Usage: python documentation_parser.py <mode>")
        print("Running for: ", sys.argv[1:])
        mode = sys.argv[1]
        if mode == "all":
            generate_all()
            sys.exit(0)
        else:
            generate_for_key(mode)
    elif len(sys.argv) != 3:
        print("Usage: python documentation_parser.py <filename> <URL>")
        print("Received arguments: ", sys.argv[1:])
        sys.exit(1)
    else:
        print("Unsupported parameters")
        print("Received arguments: ", sys.argv[1:])
        print("Usage: python documentation_parser.py <mode> (supported modes: all)")
        print("Usage: python documentation_parser.py <model_name> (see config.py)")
