# Shared dataset scoping for dataset-scanned INFORMATION_SCHEMA models

This design follows up on issue #46. It adds a shared, opt-in dataset
allowlist so users can limit fan-out across dataset-scanned
`INFORMATION_SCHEMA` models in large BigQuery estates. The design preserves
today's auto-discovery behavior when users don't set the new configuration.

## Problem statement and goals

The current `get_dataset_list()` macro discovers datasets through
`INFORMATION_SCHEMA.SCHEMATA` and returns every dataset it finds. That behavior
works for many users, but it can cause `INFORMATION_SCHEMA.PARTITIONS` and
similar models to scan too many tables in large environments. Users need one
shared way to scope dataset-level queries without disabling models.

### Goals

- Add one shared configuration surface for dataset scoping.
- Keep the new behavior opt-in and backward compatible.
- Apply the scoping rule to every model that already uses
  `get_dataset_list()`.
- Document the new setting clearly for both `vars` and environment variables.

### Non-goals

- Replace project mode or `input_gcp_projects`.
- Change default behavior for users who don't opt in.
- Add model-specific override variables for each affected model.
- Redesign materializations as part of this follow-up.

## Architecture

The package adds a new variable, tentatively `input_datasets`, and a matching
environment variable, tentatively `DBT_BQ_MONITORING_INPUT_DATASETS`. The
setting accepts either one fully qualified dataset string in the form
`project.dataset` or a list of fully qualified dataset strings.

`get_dataset_list()` remains the single decision point for dataset-scanned
`INFORMATION_SCHEMA` models. If `input_datasets` is present, the macro returns
the explicit dataset allowlist. If the setting is absent or empty, the macro
falls back to the current `SCHEMATA` discovery query.

This keeps the behavior centralized. Models that already call
`get_dataset_list()` gain the new scoping behavior automatically, which avoids
per-model configuration drift.

## Components

The implementation introduces a small set of focused changes that work
together.

1. **Variable resolution helper**
   Add a helper macro that resolves `input_datasets` from `vars` or the
   matching environment variable, following the same precedence pattern used by
   existing package settings.
2. **Dataset normalization and validation**
   Update `get_dataset_list()` to normalize a single string or list input into
   the internal backticked dataset form used in downstream SQL.
3. **Shared fan-out consumers**
   Keep `information_schema_partitions`, key and constraint usage models, and
   search index models wired through `get_dataset_list()` so they all use the
   same scoping rule.
4. **Configuration visibility**
   Surface the new setting in the package's configuration summary model so
   users can verify which value the run applied.

## Data and user flow

The runtime flow stays simple and deterministic.

1. Resolve `input_datasets` from `dbt_project.yml` or the environment.
2. If the value is missing or empty, use the existing dataset discovery query.
3. If the value is present, validate that each entry matches
   `project.dataset`.
4. Return the normalized dataset list to all models that call
   `get_dataset_list()`.
5. Fan out dataset-scanned `INFORMATION_SCHEMA` queries only across that
   explicit set.

This flow gives users a targeted escape hatch for BigQuery table-scan limits
without changing the experience for existing adopters.

## Error handling

The package must fail loudly when users provide malformed dataset identifiers.
Silent fallback would hide configuration mistakes and make debugging harder.

- If a provided dataset value doesn't match `project.dataset`, raise a clear
  dbt error that explains the expected format.
- If `input_datasets` is absent or explicitly empty, keep the current
  auto-discovery behavior.
- If a user opts into `input_datasets`, don't silently fall back to
  auto-discovery when validation fails.

## Testing and verification

The follow-up needs targeted coverage so the new configuration is safe and
predictable.

1. Verify that runs without `input_datasets` keep the current discovery path.
2. Verify that a single string and a list both normalize correctly.
3. Verify that malformed dataset identifiers fail with an explicit error.
4. Verify that the configuration summary model exposes the resolved setting.
5. Verify that the relevant docs describe both the variable and the environment
   variable.

## Next steps

After this design is approved and committed, create an implementation plan that
breaks the work into macro changes, model updates, documentation updates, and
validation steps.
