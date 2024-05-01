import sys
import requests
from bs4 import BeautifulSoup

def generate_files(filename, url):
    # Fetch the HTML content from the URL
    response = requests.get(url)
    html_content = response.text

    # Parse the HTML content using BeautifulSoup
    soup = BeautifulSoup(html_content, "html.parser")

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

    filename_yml = filename + ".yml"

    # Create the YML file
    with open(filename_yml, "w") as f:
        f.write("version: 2\n\n")
        f.write("models:\n")
        f.write("  - name: dataset_details\n")
        f.write("    description: dataset details with related information\n\n")
        f.write("    columns:\n\n")
        for column in columns:
            f.write("      - name: {name}\n".format(**column))
            f.write("        description: {description}\n".format(**column))
            f.write("        type: {type}\n\n".format(**column))

    filename_sql = filename + ".sql"

    with open(filename_sql, "w") as f:
        f.write("{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-datasets-schemata -#}\n")
        f.write("{% for project in project_list() -%}\n")
        f.write("SELECT\n")

        column_names = [column["name"].lower() for column in columns]
        f.write(",\n".join(column_names) + ",\n")

        f.write("FROM\n")
        f.write("  `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`SCHEMATA`\n")
        f.write("{% if not loop.last %}UNION ALL{% endif %}\n")
        f.write("{% endfor %}\n")

    print(f"Files '{filename_sql}' and '{filename_yml}' have been created.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <filename> <URL>")
        sys.exit(1)

    filename = sys.argv[1]
    url = sys.argv[2]
    print("----------------------------------------")
    print(f"Filename: {filename}")
    print(f"URL: {url}")
    print("----------------------------------------")
    generate_files(filename, url)
