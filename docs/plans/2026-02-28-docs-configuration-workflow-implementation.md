# Docs configuration workflow implementation plan

> **For Claude:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild docs navigation and setup guidance so new users can complete
their first successful run with fewer manual decisions and fewer setup errors.

**Architecture:** Introduce one canonical setup path (`/quickstart`), then
route users through a decision-tree configuration flow, and keep advanced
content in focused deep-dive pages. Preserve discoverability by adding a
migration map and explicit "next decision" links from legacy entry points.

**Tech Stack:** Markdown docs (Docusaurus front matter), dbt command snippets,
`rg` for content checks, and git for small iterative commits.

---

### Task 1: Add canonical quickstart entrypoint

**Files:**
- Create: `docs/quickstart.md`
- Modify: `docs/intro.md`
- Modify: `docs/installation.md`
- Test: `docs/quickstart.md` content checks with `rg`

**Step 1: Write the failing test**

```bash
rg -n "slug: /quickstart|# Quickstart|dbt run -s dbt_bigquery_monitoring" \
  docs/quickstart.md
```

Expected: FAIL because `docs/quickstart.md` does not exist yet.

**Step 2: Run test to verify it fails**

Run:

```bash
rg -n "slug: /quickstart|# Quickstart|dbt run -s dbt_bigquery_monitoring" \
  docs/quickstart.md
```

Expected: Non-zero exit code with "No such file or directory."

**Step 3: Write minimal implementation**

Create `docs/quickstart.md` with front matter (`slug: /quickstart`) and a
linear procedure:
1) install package,
2) set minimal required configuration,
3) run `dbt deps` and `dbt run -s dbt_bigquery_monitoring`,
4) validate and continue to the decision tree.

Update `docs/intro.md` and `docs/installation.md` to point users to
`/quickstart` as the canonical first-run path.

**Step 4: Run test to verify it passes**

Run:

```bash
rg -n "slug: /quickstart|# Quickstart|dbt run -s dbt_bigquery_monitoring" \
  docs/quickstart.md
```

Expected: PASS with three matches.

**Step 5: Commit**

```bash
git add docs/quickstart.md docs/intro.md docs/installation.md
git commit -m "docs: add canonical quickstart path"
```

### Task 2: Add configuration decision tree and matrix

**Files:**
- Create: `docs/configuration/decision-tree.md`
- Create: `docs/configuration/configuration-matrix.md`
- Modify: `docs/configuration/configuration.md`
- Test: `docs/configuration/decision-tree.md` and matrix link checks

**Step 1: Write the failing test**

```bash
rg -n "slug: /configuration/decision-tree|# Configuration decision tree" \
  docs/configuration/decision-tree.md
```

Expected: FAIL because file does not exist yet.

**Step 2: Run test to verify it fails**

Run:

```bash
rg -n "slug: /configuration/decision-tree|# Configuration decision tree" \
  docs/configuration/decision-tree.md
```

Expected: Non-zero exit code with missing file error.

**Step 3: Write minimal implementation**

Create `docs/configuration/decision-tree.md` with sequential decisions:
region mode versus project mode, audit logs on/off, billing export on/off,
experimental fields on/off, and required follow-up links.

Create `docs/configuration/configuration-matrix.md` with a table:

```md
| Scenario | Required vars | Optional vars | Related docs |
|----------|---------------|---------------|--------------|
| Region mode only | `bq_region` | `lookback_window_days` | ... |
| Project mode | `input_gcp_projects` | ... | ... |
| Audit logs enabled | `enable_gcp_bigquery_audit_logs` + storage refs | ... | ... |
```

Update `docs/configuration/configuration.md` so it becomes a short overview
that routes to decision tree and matrix instead of being a long mixed guide.

**Step 4: Run test to verify it passes**

Run:

```bash
rg -n "slug: /configuration/decision-tree|# Configuration decision tree" \
  docs/configuration/decision-tree.md && \
rg -n "slug: /configuration/configuration-matrix|\\| Scenario \\| Required vars" \
  docs/configuration/configuration-matrix.md
```

Expected: PASS with heading and table matches.

**Step 5: Commit**

```bash
git add docs/configuration/decision-tree.md \
  docs/configuration/configuration-matrix.md \
  docs/configuration/configuration.md
git commit -m "docs: add decision tree and configuration matrix"
```

### Task 3: Add setup wizard and simplify package settings navigation

**Files:**
- Create: `docs/configuration/setup-wizard.md`
- Modify: `docs/configuration/package-settings.md`
- Modify: `docs/running-the-package.md`
- Test: wizard and cross-link checks

**Step 1: Write the failing test**

```bash
rg -n "slug: /configuration/setup-wizard|# Setup wizard" \
  docs/configuration/setup-wizard.md
```

Expected: FAIL because file does not exist.

**Step 2: Run test to verify it fails**

Run:

```bash
rg -n "slug: /configuration/setup-wizard|# Setup wizard" \
  docs/configuration/setup-wizard.md
```

Expected: Non-zero exit code.

**Step 3: Write minimal implementation**

Create `docs/configuration/setup-wizard.md` as a linear procedure:
1) pick mode, 2) set required vars, 3) enable optional sources, 4) validate,
5) schedule run.

In `docs/configuration/package-settings.md`, add a short BLUF section and
cross-links to decision tree, matrix, and setup wizard at the top.

In `docs/running-the-package.md`, add an early link to `/configuration/setup-
wizard` so scheduling guidance follows successful configuration.

**Step 4: Run test to verify it passes**

Run:

```bash
rg -n "slug: /configuration/setup-wizard|# Setup wizard" \
  docs/configuration/setup-wizard.md && \
rg -n "/configuration/setup-wizard|/configuration/decision-tree|/configuration/configuration-matrix" \
  docs/configuration/package-settings.md docs/running-the-package.md
```

Expected: PASS with slug, heading, and link matches.

**Step 5: Commit**

```bash
git add docs/configuration/setup-wizard.md \
  docs/configuration/package-settings.md \
  docs/running-the-package.md
git commit -m "docs: add setup wizard and simplify config navigation"
```

### Task 4: Add migration map and "next decision" links

**Files:**
- Create: `docs/configuration/migration-map.md`
- Modify: `docs/configuration/audit-logs.md`
- Modify: `docs/configuration/gcp-billing.md`
- Modify: `docs/configuration/audit-logs-vs-information-schema.md`
- Modify: `docs/using-the-package.md`
- Test: migration map and next-link checks

**Step 1: Write the failing test**

```bash
rg -n "slug: /configuration/migration-map|# Migration map" \
  docs/configuration/migration-map.md
```

Expected: FAIL because file does not exist.

**Step 2: Run test to verify it fails**

Run:

```bash
rg -n "slug: /configuration/migration-map|# Migration map" \
  docs/configuration/migration-map.md
```

Expected: Non-zero exit code.

**Step 3: Write minimal implementation**

Create `docs/configuration/migration-map.md` with a table mapping old entry
pages to canonical destinations.

Add one explicit "next decision" link near the top of each modified page. Keep
the link target deterministic:
- `/configuration/setup-wizard`
- `/configuration/decision-tree`
- `/configuration/configuration-matrix`
- `/configuration/migration-map`

**Step 4: Run test to verify it passes**

Run:

```bash
rg -n "slug: /configuration/migration-map|# Migration map" \
  docs/configuration/migration-map.md && \
rg -n "/configuration/(setup-wizard|decision-tree|configuration-matrix|migration-map)" \
  docs/configuration/audit-logs.md \
  docs/configuration/gcp-billing.md \
  docs/configuration/audit-logs-vs-information-schema.md \
  docs/using-the-package.md
```

Expected: PASS with migration page matches and at least one next-link per file.

**Step 5: Commit**

```bash
git add docs/configuration/migration-map.md \
  docs/configuration/audit-logs.md \
  docs/configuration/gcp-billing.md \
  docs/configuration/audit-logs-vs-information-schema.md \
  docs/using-the-package.md
git commit -m "docs: add migration map and next-decision links"
```

### Task 5: Verify docs flow end-to-end and finalize

**Files:**
- Modify: `docs/quickstart.md` (if gaps found)
- Modify: `docs/configuration/*.md` (only where checks fail)
- Test: full docs link and command smoke checks

**Step 1: Write the failing test**

Create a temporary checklist of required canonical links and command snippets:

```bash
cat <<'EOF' >/tmp/docs_flow_checks.txt
/quickstart
/configuration/decision-tree
/configuration/configuration-matrix
/configuration/setup-wizard
/configuration/migration-map
dbt deps
dbt run -s dbt_bigquery_monitoring
dbt run-operation debug_dbt_bigquery_monitoring_variables
EOF
```

**Step 2: Run test to verify it fails**

Run:

```bash
while IFS= read -r pattern; do
  rg -n --fixed-strings "$pattern" docs >/dev/null || echo "MISSING: $pattern"
done </tmp/docs_flow_checks.txt
```

Expected: At least one `MISSING:` line before final cleanup edits.

**Step 3: Write minimal implementation**

Patch only missing references in canonical pages so every required link and
command appears at least once, and ensure each page starts with an overview
paragraph before lists.

**Step 4: Run test to verify it passes**

Run:

```bash
while IFS= read -r pattern; do
  rg -n --fixed-strings "$pattern" docs >/dev/null || exit 1
done </tmp/docs_flow_checks.txt && echo "ALL_CHECKS_PASS"
```

Expected: PASS with `ALL_CHECKS_PASS`.

**Step 5: Commit**

```bash
git add docs/quickstart.md docs/configuration/*.md docs/intro.md \
  docs/installation.md docs/running-the-package.md docs/using-the-package.md
git commit -m "docs: complete configuration workflow rewrite and validation"
```
