# Agent instructions

## Changelog

A pull request that changes package behavior needs a changie fragment under `.changes/unreleased/`. Do not edit `CHANGELOG.md` by hand.

Set `custom.Author` to `Kayrnt`:

```yaml
custom:
    Author: Kayrnt
    Issue: ""
```

`Kayrnt` is the maintainer handle used on released changelog entries. Do not use `cursoragent`, `bqbooster`, or another login. Keep the fragment file's existing indentation. When a change only corrects the author, leave `kind`, `body`, and `Issue` as they are.

## Behavior

New behavior must be opt-in and backward compatible. Defaults stay as they are, and existing column names and types stay in place, so an upgrade keeps current results.

The same change must work on dbt Core and on dbt Fusion.
