-- Repeated-query grouping key: same normalized hash collapses literal variants;
-- a null hash falls back to the raw query text so those texts stay distinct.
WITH samples AS (
    SELECT 'a' AS query_text, 'hash1' AS normalized_literals
    UNION ALL
    SELECT 'b' AS query_text, 'hash1' AS normalized_literals
    UNION ALL
    SELECT 'c' AS query_text, CAST(NULL AS STRING) AS normalized_literals
    UNION ALL
    SELECT 'c' AS query_text, CAST(NULL AS STRING) AS normalized_literals
    UNION ALL
    SELECT 'd' AS query_text, CAST(NULL AS STRING) AS normalized_literals
),

fingerprinted AS (
    SELECT
        query_text,
        {{ query_fingerprint_sql('normalized_literals', 'query_text') }} AS query_fingerprint
    FROM samples
),

grouped AS (
    SELECT
        query_fingerprint,
        COUNT(*) AS n_rows,
        COUNT(DISTINCT query_text) AS n_texts
    FROM fingerprinted
    GROUP BY query_fingerprint
)

SELECT
    query_fingerprint,
    n_rows,
    n_texts
FROM grouped
WHERE (query_fingerprint = 'hash1' AND (n_rows != 2 OR n_texts != 2))
    OR (query_fingerprint = 'c' AND n_rows != 2)
    OR (query_fingerprint = 'd' AND n_rows != 1)
    OR query_fingerprint IS NULL
    OR query_fingerprint NOT IN ('hash1', 'c', 'd')
