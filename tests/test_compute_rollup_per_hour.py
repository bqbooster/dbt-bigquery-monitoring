"""Hour rollups must match raw job totals.

compute_rollup_per_minute is already one row per minute and group, with
COUNT(DISTINCT ...) for users. compute_rollup_per_hour used to UNNEST
job_types and statement_types in the same FROM, which multiplied every SUM,
and it summed those per-minute distinct counts. There is no per-day rollup.
"""

from collections import defaultdict
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
HOUR_SQL = (
    REPO_ROOT
    / "models"
    / "monitoring"
    / "compute"
    / "intermediate"
    / "time"
    / "compute_rollup_per_hour.sql"
)
MINUTE_SQL = (
    REPO_ROOT
    / "models"
    / "monitoring"
    / "compute"
    / "intermediate"
    / "time"
    / "compute_rollup_per_minute.sql"
)
TIME_DIR = HOUR_SQL.parent


def _rollup_hour(jobs: list[dict]) -> dict:
    """Mirror the fixed hour SQL: sum additive metrics, count distinct users."""
    minutes: dict[tuple, dict] = {}
    for job in jobs:
        key = (job["hour"], job["minute"], job["project_id"])
        bucket = minutes.setdefault(
            key,
            {
                "slots": 0,
                "queries": 0,
                "users": set(),
                "job_types": defaultdict(int),
                "statement_types": defaultdict(int),
            },
        )
        bucket["slots"] += job["slots"]
        bucket["queries"] += 1
        bucket["users"].add(job["user"])
        bucket["job_types"][job["job_type"]] += 1
        bucket["statement_types"][job["statement"]] += 1

    hours: dict[tuple, dict] = {}
    for (hour, _minute, project_id), bucket in minutes.items():
        rolled = hours.setdefault(
            (hour, project_id),
            {
                "slots": 0,
                "queries": 0,
                "users": set(),
                "job_types": defaultdict(int),
                "statement_types": defaultdict(int),
            },
        )
        rolled["slots"] += bucket["slots"]
        rolled["queries"] += bucket["queries"]
        rolled["users"].update(bucket["users"])
        for value, count in bucket["job_types"].items():
            rolled["job_types"][value] += count
        for value, count in bucket["statement_types"].items():
            rolled["statement_types"][value] += count
    return hours


def test_hour_sql_does_not_cross_join_repeated_arrays() -> None:
    sql = HOUR_SQL.read_text()

    assert "LEFT JOIN UNNEST" not in sql
    assert "ARRAY_CONCAT_AGG(user_emails)" in sql
    assert "ARRAY_CONCAT_AGG(job_types)" in sql
    assert "ARRAY_CONCAT_AGG(statement_types)" in sql
    assert "COUNT(DISTINCT user_email)" in sql
    assert "COUNT(DISTINCT session_id)" in sql
    assert "SUM(unique_users)" not in sql
    assert "compute_incremental_minute_filter('minute')" in sql


def test_minute_sql_counts_distinct_users_from_jobs() -> None:
    sql = MINUTE_SQL.read_text()

    assert "LEFT JOIN UNNEST" not in sql
    assert "COUNT(DISTINCT user_email)" in sql
    assert "ARRAY_AGG(DISTINCT user_email IGNORE NULLS)" in sql
    assert "ARRAY_AGG(DISTINCT session_info.session_id IGNORE NULLS)" in sql
    assert not list(TIME_DIR.glob("*per_day*"))


def test_hour_totals_equal_raw_job_totals() -> None:
    # Same shape as the production failure: one group, several job types and
    # statement types, and a user who appears in more than one minute.
    jobs = [
        {"hour": 12, "minute": 0, "project_id": "p1", "user": "a", "slots": 100, "job_type": "QUERY", "statement": "SELECT"},
        {"hour": 12, "minute": 0, "project_id": "p1", "user": "a", "slots": 50, "job_type": "QUERY", "statement": "INSERT"},
        {"hour": 12, "minute": 1, "project_id": "p1", "user": "b", "slots": 25, "job_type": "LOAD", "statement": "SELECT"},
        {"hour": 13, "minute": 5, "project_id": "p1", "user": "c", "slots": 7, "job_type": "QUERY", "statement": "SELECT"},
    ]

    rolled = _rollup_hour(jobs)
    noon = rolled[(12, "p1")]
    one = rolled[(13, "p1")]

    assert noon["slots"] == 175
    assert noon["queries"] == 3
    assert noon["users"] == {"a", "b"}
    assert dict(noon["job_types"]) == {"QUERY": 2, "LOAD": 1}
    assert dict(noon["statement_types"]) == {"SELECT": 2, "INSERT": 1}
    assert one["slots"] == 7
    assert one["users"] == {"c"}

    # The old FROM clause emitted one row per job type x statement type, then summed.
    fanned_out_slots = 0
    for job in jobs:
        if job["hour"] != 12:
            continue
        types_in_minute = {row["job_type"] for row in jobs if row["minute"] == job["minute"] and row["hour"] == 12}
        statements_in_minute = {row["statement"] for row in jobs if row["minute"] == job["minute"] and row["hour"] == 12}
        fanned_out_slots += job["slots"] * len(types_in_minute) * len(statements_in_minute)
    assert fanned_out_slots == 325
    assert fanned_out_slots != noon["slots"]
