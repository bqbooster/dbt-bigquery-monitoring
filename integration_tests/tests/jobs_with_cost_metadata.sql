-- Validate that the jobs_with_cost metadata extraction handles comments at both the start and end of a query.
WITH sample_queries AS (
    SELECT 'leading_comment' AS scenario,
           '/* {"dbt_version": "1.9.2", "node_id": "model.package.example"} */ SELECT 1' AS query
    UNION ALL
    SELECT 'trailing_comment_with_whitespace' AS scenario,
           'SELECT 1 /* {"dbt_version": "1.9.2", "node_id": "model.package.example"} */   ' AS query
)
SELECT *
FROM (
    SELECT
        scenario,
        COALESCE(
            REPLACE(REPLACE(REGEXP_EXTRACT(query, r'^(\/\* \{+?[\w\W]+?\} \*\/)'), '/', ''), '*', ''),
            REPLACE(REPLACE(REGEXP_EXTRACT(query, r'(\/\* \{+?[\w\W]+?\} \*\/)\s*$'), '/', ''), '*', '')
        ) AS dbt_info
    FROM sample_queries
)
WHERE dbt_info IS NULL
