{#-
  One pass over stage_performance_standalone_insights.
  Empty and NULL inputs yield false flags and zero counts, which keeps
  hourly ratios honest (jobs with no insight still count in the denominator).
-#}
{% macro performance_insight_flags(insights_expr) -%}
(
  SELECT AS STRUCT
    IFNULL(COUNTIF(insight.slot_contention), 0) > 0 AS has_slot_contention,
    IFNULL(COUNTIF(insight.slot_contention), 0) AS slot_contention_stage_count,
    IFNULL(COUNTIF(insight.insufficient_shuffle_quota), 0) > 0 AS has_insufficient_shuffle_quota,
    IFNULL(COUNTIF(insight.insufficient_shuffle_quota), 0) AS insufficient_shuffle_quota_stage_count,
    IFNULL(COUNTIF(insight.partition_skew IS NOT NULL), 0) > 0 AS has_partition_skew,
    IFNULL(COUNTIF(insight.partition_skew IS NOT NULL), 0) AS partition_skew_stage_count,
    IFNULL(COUNTIF(IFNULL(ARRAY_LENGTH(insight.high_cardinality_joins), 0) > 0), 0) > 0 AS has_high_cardinality_join,
    IFNULL(SUM(IFNULL(ARRAY_LENGTH(insight.high_cardinality_joins), 0)), 0) AS high_cardinality_join_count
  FROM UNNEST(IFNULL({{ insights_expr }}, [])) AS insight
)
{%- endmacro %}

{#-
  Sum only the shuffle leaf fields. job_stages also carries steps and slot
  timings; those stay unread when the caller does not reference them.
  NULL (not zero) when stages are missing, including row-level security jobs
  whose job_stages array is empty.
-#}
{% macro shuffle_spill_sql(stages_expr='job_stages') -%}
(
  SELECT AS STRUCT
    SUM(stage.shuffle_output_bytes) AS shuffle_output_bytes,
    SUM(stage.shuffle_output_bytes_spilled) AS shuffle_output_bytes_spilled
  FROM UNNEST({{ stages_expr }}) AS stage
)
{%- endmacro %}
