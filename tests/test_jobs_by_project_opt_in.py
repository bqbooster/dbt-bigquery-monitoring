"""information_schema_jobs_by_project stays enabled unless the root project opts out.

JOBS and JOBS_BY_PROJECT are the same project-scoped view, so project mode scans
that history twice. Disabling the model in the package would remove a relation
existing projects already ref. A YAML boolean in the root project is the opt-out
that dbt Fusion honors for both true and false. A var() expression in +enabled
does not.
"""

import os
import shutil
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
GENERATED_SQL = (
    REPO_ROOT
    / "models"
    / "information_schema"
    / "jobs"
    / "information_schema_jobs_by_project.sql"
)
BASE_PROJECT = """name: gate_test
version: '1.0.0'
config-version: 2
profile: dbt_bigquery_monitoring
model-paths: ["models"]
flags:
  send_anonymous_usage_stats: False
"""


def _env() -> dict[str, str]:
    env = os.environ.copy()
    env.update(
        {
            "DBT_PROFILES_DIR": str(REPO_ROOT / "integration_tests"),
            "DBT_ENV_SECRET_BIGQUERY_TEST_STORAGE_PROJECT": "dummy-project",
            "DBT_ENV_SECRET_BIGQUERY_TEST_EXECUTION_PROJECT": "dummy-project",
            "DBT_ENV_SECRET_BIGQUERY_TEST_LOCATION": "us",
            "GITHUB_SHA": "local",
        }
    )
    return env


def _models_named(project: Path, selector: str) -> list[str]:
    result = subprocess.run(
        ["dbt", "ls", "-s", selector, "--resource-type", "model", "--output", "name"],
        cwd=project,
        env=_env(),
        text=True,
        capture_output=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return [
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip() and not line.startswith(" ")
    ]


def test_jobs_by_project_stays_enabled_in_the_package() -> None:
    project = (REPO_ROOT / "dbt_project.yml").read_text()
    generated = GENERATED_SQL.read_text()

    assert "information_schema_jobs_by_project:" not in project
    assert "+enabled: false" not in project
    assert "enable_information_schema_jobs_by_project" not in project
    assert "JOBS_BY_PROJECT" in generated
    assert "enabled=" not in generated.split("\n", 1)[0]


def test_package_models_do_not_ref_jobs_by_project() -> None:
    offenders = []
    for path in (REPO_ROOT / "models").rglob("*.sql"):
        if path.name == "information_schema_jobs_by_project.sql":
            continue
        text = path.read_text()
        if "ref('information_schema_jobs_by_project')" in text or 'ref("information_schema_jobs_by_project")' in text:
            offenders.append(str(path.relative_to(REPO_ROOT)))
    assert offenders == []


def test_root_project_boolean_gates_jobs_by_project(tmp_path: Path) -> None:
    project = tmp_path / "gate"
    project.mkdir()
    (project / "packages.yml").write_text("packages:\n  - local: " + str(REPO_ROOT) + "\n")
    (project / "models").mkdir()
    (project / "dbt_project.yml").write_text(BASE_PROJECT)
    deps = subprocess.run(
        ["dbt", "deps"],
        cwd=project,
        env=_env(),
        text=True,
        capture_output=True,
    )
    assert deps.returncode == 0, deps.stdout + deps.stderr

    assert "information_schema_jobs_by_project" in _models_named(
        project, "information_schema_jobs_by_project information_schema_jobs"
    )
    assert "information_schema_jobs" in _models_named(project, "information_schema_jobs")

    disabled = BASE_PROJECT + """
models:
  dbt_bigquery_monitoring:
    information_schema:
      jobs:
        information_schema_jobs_by_project:
          +enabled: false
"""
    (project / "dbt_project.yml").write_text(disabled)
    disabled_models = _models_named(
        project, "information_schema_jobs_by_project information_schema_jobs"
    )
    assert "information_schema_jobs_by_project" not in disabled_models
    assert "information_schema_jobs" in disabled_models

    enabled = disabled.replace("+enabled: false", "+enabled: true")
    (project / "dbt_project.yml").write_text(enabled)
    assert "information_schema_jobs_by_project" in _models_named(
        project, "information_schema_jobs_by_project"
    )

    # var() inside +enabled stays enabled, so it is not the opt-out.
    shutil.rmtree(project / "target", ignore_errors=True)
    var_false = BASE_PROJECT + "\nvars:\n  enable_information_schema_jobs_by_project: false\n"
    # The package does not read that var. Setting it must not drop the model.
    (project / "dbt_project.yml").write_text(var_false)
    assert "information_schema_jobs_by_project" in _models_named(
        project, "information_schema_jobs_by_project"
    )
