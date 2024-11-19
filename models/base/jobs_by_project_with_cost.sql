{{
   config(
    materialized=materialized_as_view_if_explicit_projects()
    )
}}
SELECT *
FROM {{ ref('jobs_with_cost') }}
