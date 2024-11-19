{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-table-storage -#}
      
      WITH base AS (
      {% if project_list()|length > 0 -%}
          {% for project in project_list() -%}
            SELECT project_id, project_number, table_catalog, table_schema, table_name, creation_time, total_rows, total_partitions, total_logical_bytes, active_logical_bytes, long_term_logical_bytes, current_physical_bytes, total_physical_bytes, active_physical_bytes, long_term_physical_bytes, time_travel_physical_bytes, storage_last_modified_time, deleted, table_type, fail_safe_physical_bytes, last_metadata_index_refresh_time
            FROM `{{ project | trim }}`.`region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE`
          {% if not loop.last %}UNION ALL{% endif %}
          {% endfor %}
      {%- else %}
          SELECT
project_id,
project_number,
table_catalog,
table_schema,
table_name,
creation_time,
total_rows,
total_partitions,
total_logical_bytes,
active_logical_bytes,
long_term_logical_bytes,
current_physical_bytes,
total_physical_bytes,
active_physical_bytes,
long_term_physical_bytes,
time_travel_physical_bytes,
storage_last_modified_time,
deleted,
table_type,
fail_safe_physical_bytes,
last_metadata_index_refresh_time
          FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`TABLE_STORAGE`
      {%- endif %}
      )

SELECT
      project_id,
project_number,
table_catalog,
table_schema,
table_name,
creation_time,
total_rows,
total_partitions,
total_logical_bytes,
active_logical_bytes,
long_term_logical_bytes,
current_physical_bytes,
total_physical_bytes,
active_physical_bytes,
long_term_physical_bytes,
time_travel_physical_bytes,
storage_last_modified_time,
deleted,
table_type,
fail_safe_physical_bytes,
last_metadata_index_refresh_time,
      FROM
      base
