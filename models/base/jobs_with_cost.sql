{{
   config(
    materialized=materialized_as_view_if_explicit_projects()
    )
}}
{{ jobs_with_cost_base("information_schema_jobs", contains_query = False) }}
