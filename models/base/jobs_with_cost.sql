{{
   config(
    materialized='view'
    )
}}
{{ jobs_with_cost_base("information_schema_jobs", contains_query = False) }}
