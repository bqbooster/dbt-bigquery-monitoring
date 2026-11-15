# Agent instructions

## Changelog

A pull request that changes package behavior needs a changie fragment under `.changes/unreleased/`. Do not edit `CHANGELOG.md` by hand.

Set `custom.Author` to the contributor's own GitHub handle. Set `custom.Issue` to the related issue number when there is one, and leave it empty when there is not:

```yaml
custom:
    Author: your-github-handle
    Issue: "123"
```

## Behavior

New behavior must be opt-in and backward compatible. Put it behind a variable so the default stays the current behavior.

Do not remove or rename existing columns. Document any full refresh that an upgrade needs.

The same change must work on dbt Core and on dbt Fusion.
