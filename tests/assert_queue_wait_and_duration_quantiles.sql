-- Queue wait is creation to start. p50/p90/p99 are offsets 50/90/99 of APPROX_QUANTILES(..., 100).
WITH waits AS (
    SELECT
        {{ queue_wait_ms() }} AS queue_wait_ms
    FROM (
        SELECT
            TIMESTAMP '2026-01-01 00:00:00 UTC' AS creation_time,
            TIMESTAMP '2026-01-01 00:02:03 UTC' AS start_time
    )
),

null_waits AS (
    SELECT
        {{ queue_wait_ms() }} AS queue_wait_ms
    FROM (
        SELECT
            TIMESTAMP '2026-01-01 00:00:00 UTC' AS creation_time,
            CAST(NULL AS TIMESTAMP) AS start_time
    )
),

quantiles AS (
    SELECT
        APPROX_QUANTILES(total_time_seconds, 100) AS duration_quantiles,
        APPROX_QUANTILES(queue_wait_ms, 100) AS queue_wait_quantiles
    FROM (
        SELECT 12 AS total_time_seconds, 3000 AS queue_wait_ms
        FROM UNNEST(GENERATE_ARRAY(1, 20))
    )
),

all_null_durations AS (
    SELECT
        APPROX_QUANTILES(total_time_seconds, 100) AS duration_quantiles
    FROM (
        SELECT CAST(NULL AS INT64) AS total_time_seconds
    )
)

SELECT 'queue_wait' AS scenario
FROM waits
WHERE queue_wait_ms != 123000
UNION ALL
SELECT 'null_start' AS scenario
FROM null_waits
WHERE queue_wait_ms IS NOT NULL
UNION ALL
SELECT 'duration_offsets' AS scenario
FROM quantiles
WHERE duration_quantiles[SAFE_OFFSET(50)] != 12
    OR duration_quantiles[SAFE_OFFSET(90)] != 12
    OR duration_quantiles[SAFE_OFFSET(99)] != 12
    OR queue_wait_quantiles[SAFE_OFFSET(50)] != 3000
    OR queue_wait_quantiles[SAFE_OFFSET(90)] != 3000
    OR queue_wait_quantiles[SAFE_OFFSET(99)] != 3000
UNION ALL
SELECT 'all_null_duration' AS scenario
FROM all_null_durations
WHERE duration_quantiles[SAFE_OFFSET(50)] IS NOT NULL
    OR duration_quantiles[SAFE_OFFSET(90)] IS NOT NULL
    OR duration_quantiles[SAFE_OFFSET(99)] IS NOT NULL
