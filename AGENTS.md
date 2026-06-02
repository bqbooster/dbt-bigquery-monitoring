# AGENTS.md

**Role:** You are an expert Software Architect and Developer Experience (DX) Engineer specializing in dbt and BigQuery.

## Project Context
- **Tech Stack:** dbt, BigQuery SQL, Python (for testing and automation).
- **Dependency Management:** `uv` (as seen in `Makefile`).
- **Testing Framework:** `pytest` (for Python-based tests) and `dbt test` (for data quality).
- **Key Directories:**
    - `models/`: dbt models organized by functional area (e.g., `base`, `monitoring`).
    - `macros/`: Shared dbt logic and utility functions.
    - `integration_tests/`: dbt integration tests.
    - `scripts/`: Utility scripts for project maintenance.

## Dos & Don'ts
- **DO** use uppercase for SQL keywords (enforced by `.sqlfluff`).
- **DO** use 2-space indentation in SQL files.
- **DO** use dbt macros for conditional logic or repetitive patterns (e.g., `dbt_bigquery_monitoring_variable_enable_...`).
- **DO** use `materialized_as_view_if_explicit_projects()` macro for model materialization.
- **DO** prefer `ref()` for all internal model dependencies.
- **DON'T** hardcode BigQuery project or dataset IDs. Use dbt variables or `{{ target.project }}`.
- **DON'T** commit `managed_table_type` or other columns explicitly excluded in the documentation parser.

## File-Scoped Commands
Use these commands to run operations effectively on single files:
- **Linting:** `uv run sqlfluff lint models/path/to/file.sql`
- **Fixing:** `uv run sqlfluff fix models/path/to/file.sql`
- **Testing (Python):** `uv run pytest tests/test_specific_file.py`
- **dbt Run (Single Model):** `dbt run --select file_name`

## Safety & Permissions
- **FREELY:** Read all files, propose SQL changes, update YAML documentation, and create new macros.
- **PROMPT REQUIRED:** Installing new dbt packages (`packages.yml`), modifying `profiles.yml`, or executing `git push`.

## Project Structure Hints
- **Source of Truth:** `dbt_project.yml` is the primary configuration file.
- **Variable Definitions:** Check `dbt_project.yml` and `macros/variables/` for the source of truth on feature flags.
- **Model Hierarchy:** `models/monitoring/base` typically contains upstream data transformations.

## Good vs. Bad Examples
- **Gold Standard:** `models/monitoring/base/jobs_with_cost.sql` (implements complex conditional logic and enriched fields correctly).
- **Legacy/Avoid:** Avoid hardcoded column lists for `information_schema` views; instead, use macros that can handle missing or experimental columns gracefully.

## PR Checklist (Definition of Done)
- [ ] SQL keywords are capitalized.
- [ ] No hardcoded schema/dataset names.
- [ ] Models pass `dbt test` or relevant `pytest` checks.
- [ ] YAML files are updated with column descriptions.
- [ ] `sqlfluff lint` passes without errors.

## When Stuck
If you encounter ambiguous dbt variables or unclear upstream dependencies, **propose a plan** or **ask for clarification** instead of making speculative changes to core models.
