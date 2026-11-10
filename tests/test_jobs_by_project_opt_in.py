"""JOBS_BY_PROJECT is the same data as JOBS and must stay opt-in.

Project mode materializes every enabled INFORMATION_SCHEMA model. Leaving
information_schema_jobs_by_project enabled repeats the jobs scan. The gate
is a boolean in dbt_project.yml. A Jinja enabled flag renders as text and
Fusion treats that text as enabled.
"""

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
GENERATED_SQL = (
    REPO_ROOT
    / "models"
    / "information_schema"
    / "jobs"
    / "information_schema_jobs_by_project.sql"
)


def test_jobs_by_project_is_opt_in_outside_the_generated_sql() -> None:
    project = (REPO_ROOT / "dbt_project.yml").read_text()
    generated = GENERATED_SQL.read_text()

    assert "information_schema_jobs_by_project:" in project
    assert "+enabled: false" in project
    assert "dbt_bigquery_monitoring_variable_enable_information_schema_jobs_by_project" not in project
    assert "JOBS_BY_PROJECT" in generated
    assert "enabled=" not in generated.split("\n", 1)[0]


def test_package_models_do_not_ref_jobs_by_project() -> None:
    offenders = []
    for path in (REPO_ROOT / "models").rglob("*.sql"):
        if path.name == "information_schema_jobs_by_project.sql":
            continue
        if "information_schema_jobs_by_project" in path.read_text():
            offenders.append(str(path.relative_to(REPO_ROOT)))
    assert offenders == []
