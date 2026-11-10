-- Flag extraction and shuffle spill sums used by job_performance_insights.
WITH samples AS (
    SELECT
        'contention_skew_and_joins' AS scenario,
        TRUE AS expect_contention,
        1 AS expect_contention_stages,
        FALSE AS expect_shuffle_quota,
        0 AS expect_shuffle_quota_stages,
        TRUE AS expect_skew,
        1 AS expect_skew_stages,
        TRUE AS expect_join,
        2 AS expect_join_count,
        [
            STRUCT(
                1 AS stage_id,
                TRUE AS slot_contention,
                FALSE AS insufficient_shuffle_quota,
                STRUCT([STRUCT(9 AS stage_id)] AS skew_sources) AS partition_skew,
                [
                    STRUCT(10 AS left_rows, 20 AS right_rows, 30 AS output_rows, 1 AS step_index),
                    STRUCT(1 AS left_rows, 1 AS right_rows, 1 AS output_rows, 2 AS step_index)
                ] AS high_cardinality_joins
            ),
            STRUCT(
                2 AS stage_id,
                FALSE AS slot_contention,
                FALSE AS insufficient_shuffle_quota,
                CAST(NULL AS STRUCT<skew_sources ARRAY<STRUCT<stage_id INT64>>>) AS partition_skew,
                CAST(NULL AS ARRAY<STRUCT<
                    left_rows INT64, right_rows INT64, output_rows INT64, step_index INT64
                >>) AS high_cardinality_joins
            )
        ] AS insights
    UNION ALL
    SELECT
        'shuffle_quota_only' AS scenario,
        FALSE AS expect_contention,
        0 AS expect_contention_stages,
        TRUE AS expect_shuffle_quota,
        1 AS expect_shuffle_quota_stages,
        FALSE AS expect_skew,
        0 AS expect_skew_stages,
        FALSE AS expect_join,
        0 AS expect_join_count,
        [
            STRUCT(
                3 AS stage_id,
                FALSE AS slot_contention,
                TRUE AS insufficient_shuffle_quota,
                CAST(NULL AS STRUCT<skew_sources ARRAY<STRUCT<stage_id INT64>>>) AS partition_skew,
                CAST([] AS ARRAY<STRUCT<
                    left_rows INT64, right_rows INT64, output_rows INT64, step_index INT64
                >>) AS high_cardinality_joins
            )
        ] AS insights
    UNION ALL
    SELECT
        'null_insights' AS scenario,
        FALSE AS expect_contention,
        0 AS expect_contention_stages,
        FALSE AS expect_shuffle_quota,
        0 AS expect_shuffle_quota_stages,
        FALSE AS expect_skew,
        0 AS expect_skew_stages,
        FALSE AS expect_join,
        0 AS expect_join_count,
        CAST(NULL AS ARRAY<STRUCT<
            stage_id INT64,
            slot_contention BOOL,
            insufficient_shuffle_quota BOOL,
            partition_skew STRUCT<skew_sources ARRAY<STRUCT<stage_id INT64>>>,
            high_cardinality_joins ARRAY<STRUCT<
                left_rows INT64, right_rows INT64, output_rows INT64, step_index INT64
            >>
        >>) AS insights
    UNION ALL
    SELECT
        'empty_insights' AS scenario,
        FALSE AS expect_contention,
        0 AS expect_contention_stages,
        FALSE AS expect_shuffle_quota,
        0 AS expect_shuffle_quota_stages,
        FALSE AS expect_skew,
        0 AS expect_skew_stages,
        FALSE AS expect_join,
        0 AS expect_join_count,
        CAST([] AS ARRAY<STRUCT<
            stage_id INT64,
            slot_contention BOOL,
            insufficient_shuffle_quota BOOL,
            partition_skew STRUCT<skew_sources ARRAY<STRUCT<stage_id INT64>>>,
            high_cardinality_joins ARRAY<STRUCT<
                left_rows INT64, right_rows INT64, output_rows INT64, step_index INT64
            >>
        >>) AS insights
),

flag_mismatches AS (
    SELECT scenario
    FROM (
        SELECT
            scenario,
            {{ performance_insight_flags('insights') }} AS flags,
            expect_contention,
            expect_contention_stages,
            expect_shuffle_quota,
            expect_shuffle_quota_stages,
            expect_skew,
            expect_skew_stages,
            expect_join,
            expect_join_count
        FROM samples
    )
    WHERE flags.has_slot_contention != expect_contention
        OR flags.slot_contention_stage_count != expect_contention_stages
        OR flags.has_insufficient_shuffle_quota != expect_shuffle_quota
        OR flags.insufficient_shuffle_quota_stage_count != expect_shuffle_quota_stages
        OR flags.has_partition_skew != expect_skew
        OR flags.partition_skew_stage_count != expect_skew_stages
        OR flags.has_high_cardinality_join != expect_join
        OR flags.high_cardinality_join_count != expect_join_count
),

spill_mismatches AS (
    SELECT 'spill_sum' AS scenario
    FROM (
        SELECT {{ shuffle_spill_sql('stages') }} AS spill
        FROM (
            SELECT [
                STRUCT(10 AS shuffle_output_bytes, 4 AS shuffle_output_bytes_spilled),
                STRUCT(5 AS shuffle_output_bytes, 1 AS shuffle_output_bytes_spilled)
            ] AS stages
        )
    )
    WHERE spill.shuffle_output_bytes != 15
        OR spill.shuffle_output_bytes_spilled != 5
    UNION ALL
    SELECT 'null_stages' AS scenario
    FROM (
        SELECT {{ shuffle_spill_sql('stages') }} AS spill
        FROM (
            SELECT CAST(NULL AS ARRAY<STRUCT<
                shuffle_output_bytes INT64,
                shuffle_output_bytes_spilled INT64
            >>) AS stages
        )
    )
    WHERE spill.shuffle_output_bytes IS NOT NULL
        OR spill.shuffle_output_bytes_spilled IS NOT NULL
    UNION ALL
    SELECT 'empty_stages' AS scenario
    FROM (
        SELECT {{ shuffle_spill_sql('stages') }} AS spill
        FROM (
            SELECT CAST([] AS ARRAY<STRUCT<
                shuffle_output_bytes INT64,
                shuffle_output_bytes_spilled INT64
            >>) AS stages
        )
    )
    WHERE spill.shuffle_output_bytes IS NOT NULL
        OR spill.shuffle_output_bytes_spilled IS NOT NULL
)

SELECT scenario FROM flag_mismatches
UNION ALL
SELECT scenario FROM spill_mismatches
