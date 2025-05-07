{{
   config(
    materialized=materialized_as_view_if_explicit_projects()
    )
}}
SELECT
catalog_name as project_id,
schema_name as dataset_id,
COALESCE(ANY_VALUE(IF(option_name = "storage_billing_model", option_value, NULL)), "LOGICAL") storage_billing_model
FROM {{ ref('information_schema_schemata_options') }}
GROUP BY project_id, dataset_id
