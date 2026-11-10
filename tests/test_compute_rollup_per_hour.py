"""Hour rollups must match raw job totals without changing the output schema.

compute_rollup_per_minute is one row per minute and group. compute_rollup_per_hour
used to UNNEST job_types and statement_types in the same FROM, which multiplied
every SUM, and it summed per-minute distinct counts. There is no per-day rollup.
Nothing downstream refs the hour model. The minute model appends id arrays so an
existing incremental table can add them with on_schema_change=append_new_columns.
"""

from collections import defaultdict
from datetime import datetime, timedelta
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
FILTER_SQL = REPO_ROOT / "macros" / "compute_incremental_minute_filter.sql"
TIME_DIR = HOUR_SQL.parent

HOUR_OUTPUT_COLUMNS = [
    "hour",
    "project_id",
    "reservation_id",
    "bi_engine_mode",
    "client_type",
    "edition",
    "total_query_cost",
    "failing_query_cost",
    "total_bytes_processed",
    "total_bytes_billed",
    "total_slot_ms",
    "query_count",
    "unique_users",
    "unique_sessions",
    "cache_hits",
    "job_state",
    "job_types",
    "statement_types",
    "avg_duration_seconds",
    "median_duration_seconds",
]


def _minute_from_jobs(jobs: list[dict]) -> list[dict]:
    """One minute row per (minute, project), matching compute_rollup_per_minute."""
    buckets: dict[tuple, dict] = {}
    for job in jobs:
        key = (job["minute"], job["project_id"])
        bucket = buckets.setdefault(
            key,
            {
                "minute": job["minute"],
                "project_id": job["project_id"],
                "slots": 0,
                "queries": 0,
                "users": set(),
                "sessions": set(),
                "job_types": defaultdict(int),
                "statement_types": defaultdict(int),
            },
        )
        bucket["slots"] += job["slots"]
        bucket["queries"] += 1
        if job.get("user") is not None:
            bucket["users"].add(job["user"])
        if job.get("session") is not None:
            bucket["sessions"].add(job["session"])
        if job.get("job_type") is not None:
            bucket["job_types"][job["job_type"]] += 1
        if job.get("statement") is not None:
            bucket["statement_types"][job["statement"]] += 1
    rows = []
    for bucket in buckets.values():
        rows.append(
            {
                "minute": bucket["minute"],
                "project_id": bucket["project_id"],
                "slots": bucket["slots"],
                "queries": bucket["queries"],
                "unique_users": len(bucket["users"]),
                "unique_sessions": len(bucket["sessions"]),
                "user_emails": sorted(bucket["users"]) if bucket["users"] else None,
                "session_ids": sorted(bucket["sessions"]) if bucket["sessions"] else None,
                "job_types": dict(bucket["job_types"]),
                "statement_types": dict(bucket["statement_types"]),
            }
        )
    return rows


def _hour_from_minutes(minutes: list[dict], *, incremental_floor: datetime | None = None) -> dict:
    """Mirror the hour SQL, including the NULL-array fallback and top-20 cap."""
    grouped: dict[tuple, list] = defaultdict(list)
    for row in minutes:
        if incremental_floor is not None and row["minute"] < incremental_floor:
            continue
        hour = row["minute"].replace(minute=0, second=0, microsecond=0)
        grouped[(hour, row["project_id"])].append(row)

    rolled = {}
    for key, rows in grouped.items():
        users_ready = all(row["user_emails"] is not None for row in rows)
        sessions_ready = all(row["session_ids"] is not None for row in rows)
        job_types: dict[str, int] = defaultdict(int)
        statement_types: dict[str, int] = defaultdict(int)
        for row in rows:
            for value, count in (row["job_types"] or {}).items():
                if value is not None:
                    job_types[value] += count
            for value, count in (row["statement_types"] or {}).items():
                if value is not None:
                    statement_types[value] += count
        if users_ready:
            users = set()
            for row in rows:
                users.update(row["user_emails"])
            unique_users = len(users)
        else:
            unique_users = sum(row["unique_users"] for row in rows)
        if sessions_ready:
            sessions = set()
            for row in rows:
                sessions.update(row["session_ids"])
            unique_sessions = len(sessions)
        else:
            unique_sessions = sum(row["unique_sessions"] for row in rows)
        rolled[key] = {
            "slots": sum(row["slots"] for row in rows),
            "queries": sum(row["queries"] for row in rows),
            "unique_users": unique_users,
            "unique_sessions": unique_sessions,
            "job_types": dict(sorted(job_types.items(), key=lambda item: (-item[1], item[0]))[:20]),
            "statement_types": dict(
                sorted(statement_types.items(), key=lambda item: (-item[1], item[0]))[:30]
            ),
        }
    return rolled


def _select_list(sql: str) -> str:
    return sql.split("SELECT", 1)[1].split("FROM", 1)[0]


def test_hour_sql_does_not_cross_join_repeated_arrays() -> None:
    sql = HOUR_SQL.read_text()

    assert "LEFT JOIN UNNEST" not in sql
    assert "ARRAY_CONCAT_AGG(user_emails)" in sql
    assert "ARRAY_CONCAT_AGG(job_types)" in sql
    assert "ARRAY_CONCAT_AGG(statement_types)" in sql
    assert "user_emails_backfilled" in sql
    assert "summed_unique_users" in sql
    assert "COALESCE(job_types, [])" in sql
    assert "compute_incremental_minute_filter('minute')" in sql
    output_block = "\n  " + ",\n  ".join(
        [
            "hour",
            "project_id",
            "reservation_id",
            "bi_engine_mode",
            "client_type",
            "edition",
        ]
    )
    assert output_block in sql
    for column in HOUR_OUTPUT_COLUMNS:
        assert f"{column}" in sql.split("FROM grouped", 1)[0]


def test_minute_appends_id_arrays_without_reordering_existing_columns() -> None:
    sql = MINUTE_SQL.read_text()
    select_list = _select_list(sql)
    emails = select_list.index("AS user_emails")
    sessions = select_list.index("AS session_ids")

    assert "on_schema_change='append_new_columns'" in sql
    assert "LEFT JOIN UNNEST" not in sql
    assert "COUNT(DISTINCT user_email)" in sql
    assert "ARRAY_AGG(DISTINCT user_email IGNORE NULLS) AS user_emails" in sql
    assert emails < sessions
    assert select_list.rfind("AS median_duration_seconds") < emails
    assert not list(TIME_DIR.glob("*per_day*"))
    # Downstream cost rollups list their columns, so the appended arrays stay on this table.
    cost_minute = (
        REPO_ROOT
        / "models"
        / "monitoring"
        / "compute"
        / "intermediate"
        / "cost"
        / "compute_cost_per_minute.sql"
    ).read_text()
    assert "user_emails" not in cost_minute
    assert "ref('compute_rollup_per_minute')" in cost_minute


def test_no_model_reads_compute_rollup_per_hour() -> None:
    offenders = []
    for path in (REPO_ROOT / "models").rglob("*.sql"):
        if path.name == "compute_rollup_per_hour.sql":
            continue
        if "ref('compute_rollup_per_hour')" in path.read_text() or 'ref("compute_rollup_per_hour")' in path.read_text():
            offenders.append(str(path.relative_to(REPO_ROOT)))
    assert offenders == []


def test_incremental_filter_keeps_the_max_hour_and_drops_the_previous_one() -> None:
    macro = FILTER_SQL.read_text()

    assert "{% if is_incremental() %}" in macro
    assert "WHERE {{ timestamp_column }} >= {{ get_partition_timestamp() }}" in macro
    # Day-partitioned hour table: _dbt_max_partition is midnight, truncated to the hour.
    floor = datetime(2026, 11, 10)
    previous = floor - timedelta(minutes=1)
    current = floor
    late = datetime(2026, 11, 9, 12, 0)
    minutes = _minute_from_jobs(
        [
            {"minute": previous, "project_id": "p1", "user": "a", "session": "s", "slots": 5, "job_type": "QUERY", "statement": "SELECT"},
            {"minute": current, "project_id": "p1", "user": "b", "session": "s2", "slots": 8, "job_type": "QUERY", "statement": "SELECT"},
            {"minute": late, "project_id": "p1", "user": "c", "session": "s3", "slots": 100, "job_type": "LOAD", "statement": "SELECT"},
        ]
    )

    incremental = _hour_from_minutes(minutes, incremental_floor=floor)
    full_refresh = _hour_from_minutes(minutes, incremental_floor=None)

    assert set(incremental) == {(datetime(2026, 11, 10), "p1")}
    assert incremental[(datetime(2026, 11, 10), "p1")]["slots"] == 8
    # Full refresh rewrites every hour, including late rows before the incremental floor.
    assert full_refresh[(datetime(2026, 11, 9, 23), "p1")]["slots"] == 5
    assert full_refresh[(datetime(2026, 11, 9, 12), "p1")]["slots"] == 100
    assert full_refresh[(datetime(2026, 11, 10), "p1")]["slots"] == 8
    assert sum(row["slots"] for row in full_refresh.values()) == 113


def test_hour_totals_equal_raw_job_totals_across_projects_and_hours() -> None:
    jobs = [
        {"minute": datetime(2026, 11, 1, 12, 0), "project_id": "p1", "user": "a", "session": "s1", "slots": 100, "job_type": "QUERY", "statement": "SELECT"},
        {"minute": datetime(2026, 11, 1, 12, 0), "project_id": "p1", "user": "a", "session": "s1", "slots": 50, "job_type": "QUERY", "statement": "INSERT"},
        {"minute": datetime(2026, 11, 1, 12, 1), "project_id": "p1", "user": "b", "session": "s2", "slots": 25, "job_type": "LOAD", "statement": "SELECT"},
        {"minute": datetime(2026, 11, 1, 12, 30), "project_id": "p2", "user": "a", "session": "s1", "slots": 9, "job_type": "QUERY", "statement": "SELECT"},
        {"minute": datetime(2026, 11, 1, 13, 5), "project_id": "p1", "user": "a", "session": "s1", "slots": 7, "job_type": "QUERY", "statement": "SELECT"},
        {"minute": datetime(2026, 11, 1, 13, 6), "project_id": "p1", "user": None, "session": None, "slots": 3, "job_type": None, "statement": None},
    ]

    rolled = _hour_from_minutes(_minute_from_jobs(jobs))
    noon = rolled[(datetime(2026, 11, 1, 12), "p1")]
    noon_p2 = rolled[(datetime(2026, 11, 1, 12), "p2")]
    one = rolled[(datetime(2026, 11, 1, 13), "p1")]

    assert noon["slots"] == 175
    assert noon["queries"] == 3
    assert noon["unique_users"] == 2
    assert noon["unique_sessions"] == 2
    assert noon["job_types"] == {"QUERY": 2, "LOAD": 1}
    assert noon["statement_types"] == {"SELECT": 2, "INSERT": 1}
    assert noon_p2["slots"] == 9
    assert noon_p2["unique_users"] == 1
    # Same user in the next hour is counted again for that hour, not dropped.
    assert one["slots"] == 10
    assert one["queries"] == 2
    assert one["unique_users"] == 1
    assert one["unique_sessions"] == 1
    assert one["job_types"] == {"QUERY": 1}
    assert one["statement_types"] == {"SELECT": 1}

    raw_slots = sum(job["slots"] for job in jobs)
    assert sum(row["slots"] for row in rolled.values()) == raw_slots


def test_null_id_arrays_fall_back_to_summed_minute_counts() -> None:
    legacy = {
        "minute": datetime(2026, 11, 2, 8, 0),
        "project_id": "p1",
        "slots": 40,
        "queries": 2,
        "unique_users": 4,
        "unique_sessions": 3,
        "user_emails": None,
        "session_ids": None,
        "job_types": None,
        "statement_types": None,
    }
    backfilled = {
        "minute": datetime(2026, 11, 2, 8, 10),
        "project_id": "p1",
        "slots": 10,
        "queries": 1,
        "unique_users": 2,
        "unique_sessions": 1,
        "user_emails": ["a@example.com"],
        "session_ids": ["s1"],
        "job_types": {None: 1},
        "statement_types": {},
    }

    mixed = _hour_from_minutes([legacy, backfilled])[(datetime(2026, 11, 2, 8), "p1")]
    only_legacy = _hour_from_minutes([legacy])[(datetime(2026, 11, 2, 8), "p1")]

    assert mixed["slots"] == 50
    assert mixed["queries"] == 3
    assert mixed["unique_users"] == 6
    assert mixed["unique_sessions"] == 4
    assert mixed["job_types"] == {}
    assert mixed["statement_types"] == {}
    assert only_legacy["unique_users"] == 4
    assert only_legacy["unique_sessions"] == 3


def test_old_cross_join_would_not_match_raw_totals() -> None:
    jobs = [
        {"minute": datetime(2026, 11, 1, 12, 0), "project_id": "p1", "user": "a", "session": "s1", "slots": 100, "job_type": "QUERY", "statement": "SELECT"},
        {"minute": datetime(2026, 11, 1, 12, 0), "project_id": "p1", "user": "a", "session": "s1", "slots": 50, "job_type": "QUERY", "statement": "INSERT"},
        {"minute": datetime(2026, 11, 1, 12, 1), "project_id": "p1", "user": "b", "session": "s2", "slots": 25, "job_type": "LOAD", "statement": "SELECT"},
    ]
    rolled = _hour_from_minutes(_minute_from_jobs(jobs))
    noon = rolled[(datetime(2026, 11, 1, 12), "p1")]
    fanned_out_slots = 0
    for job in jobs:
        types_in_minute = {
            row["job_type"]
            for row in jobs
            if row["minute"] == job["minute"] and row["job_type"] is not None
        }
        statements_in_minute = {
            row["statement"]
            for row in jobs
            if row["minute"] == job["minute"] and row["statement"] is not None
        }
        fanned_out_slots += job["slots"] * len(types_in_minute) * len(statements_in_minute)

    assert fanned_out_slots == 325
    assert noon["slots"] == 175
