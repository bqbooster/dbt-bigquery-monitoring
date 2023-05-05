{{
   config(
    materialized='view'
    )
}}
{{ jobs_with_cost_base("JOBS_BY_PROJECT", False) }}
