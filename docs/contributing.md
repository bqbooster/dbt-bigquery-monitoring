---
sidebar_position: 8
slug: /contributing
---

# Contributing

## Install setup

We recommend managing dependencies and running commands with `uv`. You're free to use the tooling you prefer, but the following setup keeps things consistent with project automation:

- uv (recommended) to manage the virtual environment and execute project commands
- pipx (optional) to install global helper CLIs such as changie
- SQLFluff (lint SQL)
- changie (generate CHANGELOG entries)

### uv quickstart

Install `uv` by following the [official instructions](https://docs.astral.sh/uv/getting-started/installation/) or run:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Then bootstrap the project environment and install dev dependencies:

```bash
uv sync --group dev
```

Run project commands through `uv` to ensure they use the managed environment. For example:

```bash
uv run sqlfluff lint
```

### tool setup guide

To install pipx:

```bash
pip install pipx
pipx ensurepath
```

Then you'll be able to install standalone tools such as changie with pipx if you prefer a global installation.

To install changie, there are few options depending on your OS.
See the [installation guide](https://changie.dev/guide/installation/) for more details, or install it with `pipx install changie`.

To configure your dbt profile, run following command and follow the prompts:

```bash
dbt init
```

## Development workflow

- Fork the repo
- Create a branch from `main`
- Make your changes
- Run the tests (for example `uv run dbt test` or your preferred command)
- Create your changelog entry with `changie new` (don't edit directly the CHANGELOG.md)
- Commit your changes (it will run the linter through pre-commit)
- Push your branch and open a PR on the repository

## Adding a CHANGELOG Entry

We use changie to generate CHANGELOG entries. Note: Do not edit the CHANGELOG.md directly. Your modifications will be lost.

Follow the steps to [install changie](https://changie.dev/guide/installation/) for your system.

Once changie is installed and your PR is created, simply run `changie new` and changie will walk you through the process of creating a changelog entry. Commit the file that's created and your changelog entry is complete!

### SQLFluff

We use SQLFluff to keep SQL style consistent. By installing `pre-commit` per the initial setup guide above, SQLFluff will run automatically when you make a commit locally. A GitHub action automatically tests pull requests and adds annotations where there are failures.

Lint all models in the /models directory:
```bash
uv run sqlfluff lint
```

Fix all models in the /models directory:
```bash
uv run sqlfluff fix
```

Lint (or substitute lint to fix) a specific model:
```bash
uv run sqlfluff lint -- models/path/to/model.sql
```

Lint (or substitute lint to fix) a specific directory:
```bash
uv run sqlfluff lint -- models/path/to/directory
```

#### Rules

Enforced rules are defined within `.sqlfluff`. To view the full list of available rules and their configuration, see the [SQLFluff documentation](https://docs.sqlfluff.com/en/stable/rules.html).

## Generation of dbt base google models

dbt base google models are generated in another dedicated project hosted in:
https://github.com/bqbooster/dbt-bigquery-monitoring-parser

It was separated to ensure that users don't install the parser (and tests) when they install the dbt package.

## Documentation website

Documentation is generated with Docusaurus and hosted on GitHub pages.
The content is hosted directly in the `docs` folder of [the main repository](https://github.com/bqbooster/dbt-bigquery-monitoring).
The template is hosted in a separate repository: [bqbooster/dbt-bigquery-monitoring-docs](https://github.com/bqbooster/dbt-bigquery-monitoring-docs).
