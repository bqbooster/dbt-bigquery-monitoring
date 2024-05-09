{{
   config(
    materialized='view'
    )
}}
{{ jobs_with_cost_base("information_schema_jobs_by_project", contains_query = True) }}
