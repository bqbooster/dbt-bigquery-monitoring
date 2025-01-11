{{ config(materialization=dbt_bigquery_monitoring_materialization()) }}
{# More details about base table in https://cloud.google.com/bigquery/docs/information-schema-capacity-commitments -#}

SELECT ddl, project_id, project_number, capacity_commitment_id, commitment_plan, state, slot_count, edition, is_flat_rate, renewal_plan
FROM `region-{{ var('bq_region') }}`.`INFORMATION_SCHEMA`.`CAPACITY_COMMITMENTS`
