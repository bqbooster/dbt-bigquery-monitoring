{#-
  INFORMATION_SCHEMA query hash. NULL for cache hits, failed jobs, and
  non-GoogleSQL jobs, and always NULL when INFORMATION_SCHEMA structs
  are not available (audit-log-only mode).
-#}
{% macro normalized_literals_sql() %}
    {%- if information_schema_job_columns_available() -%}
        query_info.query_hashes.normalized_literals
    {%- else -%}
        CAST(NULL AS STRING)
    {%- endif -%}
{% endmacro %}

{#-
  Grouping key for repeated-query models.
  Parameterized repeats share normalized_literals. When that hash is null,
  fall back to the raw query text so identical statements still aggregate
  and distinct texts do not collapse into one NULL group.
-#}
{% macro query_fingerprint_sql(hash_expr, query_expr) -%}
COALESCE({{ hash_expr }}, {{ query_expr }})
{%- endmacro %}
