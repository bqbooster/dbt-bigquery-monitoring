{#-
 set the query comment for current model to serialize metadata to be read by the model
 This macro is largely inspired by dbt-snowflake-query-tags one
-#}
{% macro get_query_comment(node) %}
    {%- set comment_dict = {} -%}
    {%- do comment_dict.update(
        app='dbt',
        dbt_bigquery_monitoring_version="0.8.0",
        dbt_version=dbt_version,
        project_name=project_name,
        target_name=target.name,
        target_database=target.database,
        target_schema=target.schema,
        invocation_id=invocation_id
    ) -%}

    {%- if node is not none -%}
        {%- do comment_dict.update(
            node_name=node.name,
            node_alias=node.alias,
            node_package_name=node.package_name,
            node_original_file_path=node.original_file_path,
            node_database=node.database,
            node_schema=node.schema,
            node_id=node.unique_id,
            node_resource_type=node.resource_type,
            node_meta=node.config.meta,
            node_tags=node.tags,
            full_refresh=flags.FULL_REFRESH,
            which=flags.WHICH,
        ) -%}

        {%- if flags.INVOCATION_COMMAND -%}
            {%- do comment_dict.update(
                invocation_command=flags.INVOCATION_COMMAND
            ) -%}
        {%- endif -%}

        {%- if node.resource_type != ('seed') -%} {# Otherwise this throws an error saying 'Seeds cannot depend on other nodes.' #}
            {%- if node.refs is defined -%}
                {% set refs = [] %}
                {% for ref in node.refs %}
                    {%- if dbt_version >= '1.5.0' -%}
                        {%- do refs.append(ref.name) -%}
                    {%- else -%}
                        {%- do refs.append(ref[0]) -%}
                    {%- endif -%}
                {% endfor %}
                {%- do comment_dict.update(
                    node_refs=refs | unique | list
                ) -%}
            {%- endif -%}
        {%- endif -%}
        {%- if node.resource_type == 'model' -%}
            {%- do comment_dict.update(
                materialized=node.config.materialized,
            ) -%}

            {%- if node.config.materialized == 'incremental' and node.config.incremental_strategy is defined -%}
                {%- do comment_dict.update(
                    incremental_strategy=node.config.incremental_strategy,
                ) -%}
            {%- endif -%}

            {%- if node.config.partition_by is defined -%}

                {%- if node.config.partition_by.copy_partitions is defined -%}
                {%- do comment_dict.update(
                    copy_partitions=node.config.partition_by.copy_partitions,
                ) -%}
                {%- endif -%}

                {%- if node.config.partition_by.time_ingestion_partitioning is defined -%}
                {%- do comment_dict.update(
                    time_ingestion_partitioning=node.config.partition_by.time_ingestion_partitioning,
                ) -%}
                {%- endif -%}

            {%- endif -%}

        {%- endif -%}
    {%- endif -%}

    {%- if env_var('DBT_CLOUD_PROJECT_ID', False) -%}
    {%- do comment_dict.update(
        dbt_cloud_project_id=env_var('DBT_CLOUD_PROJECT_ID')
    ) -%}
    {%- endif -%}

    {%- if env_var('DBT_CLOUD_JOB_ID', False) -%}
    {%- do comment_dict.update(
        dbt_cloud_job_id=env_var('DBT_CLOUD_JOB_ID')
    ) -%}
    {%- endif -%}

    {%- if env_var('DBT_CLOUD_RUN_ID', False) -%}
    {%- do comment_dict.update(
        dbt_cloud_run_id=env_var('DBT_CLOUD_RUN_ID')
    ) -%}
    {%- endif -%}

    {%- if env_var('DBT_CLOUD_RUN_REASON_CATEGORY', False) -%}
    {%- do comment_dict.update(
        dbt_cloud_run_reason_category=env_var('DBT_CLOUD_RUN_REASON_CATEGORY')
    ) -%}
    {%- endif -%}

    {%- if env_var('DBT_CLOUD_RUN_REASON', False) -%}
    {%- do comment_dict.update(
        dbt_cloud_run_reason=env_var('DBT_CLOUD_RUN_REASON')
    ) -%}
    {%- endif -%}

    {{ log("comment_dict" ~ comment_dict) }}

    {{ return(tojson(comment_dict)) }}
{% endmacro %}
