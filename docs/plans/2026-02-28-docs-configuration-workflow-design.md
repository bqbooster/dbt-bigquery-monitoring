# Docs and configuration workflow redesign

This design defines a full information architecture overhaul for onboarding and
configuration documentation. The goal is to reduce setup mistakes for new users
by giving one clear path for common setups with fewer manual decisions.

## Problem statement and goals

New users can hit conflicting or fragmented setup guidance across pages, which
increases guesswork during first-time configuration. This redesign creates one
canonical flow for initial success, then routes advanced use cases into focused
reference content.

### Goals

- Reduce setup mistakes in first-time adoption.
- Make the common setup path explicit and linear.
- Remove conflicting guidance by mapping all legacy docs to canonical pages.

### Non-goals

- Changing dbt model behavior.
- Introducing new runtime configuration features.
- Rewriting package SQL logic as part of this docs initiative.

## Architecture

The new docs architecture has three top-level tracks that match user intent at
each stage. Users start in **Quickstart**, branch through a guided
configuration path, and then move into advanced references only if needed.

1. **Quickstart**: shortest path to first successful run.
2. **Configuration decision tree**: guided choices for `profiles.yml` and vars.
3. **Deep dives**: advanced scenarios, edge cases, and full references.

Every existing docs page maps to exactly one canonical destination in this
structure to prevent contradictory instructions.

## Components

This redesign introduces a small set of high-value pages that become the single
source of truth for setup decisions.

1. **Canonical Quickstart page**
   - Covers install, minimum required configuration, and first run commands.
   - Links directly to validation and troubleshooting.
2. **Configuration matrix**
   - Lists required and optional variables by scenario.
   - Distinguishes default, recommended, and advanced values.
3. **Setup wizard page**
   - Presents sequential, decision-based configuration steps.
   - Routes users to specific examples based on environment complexity.
4. **Migration map for legacy paths**
   - Shows where each old page moves in the new IA.
   - Prevents dead ends during transition.
5. **Next-decision links across pages**
   - Ensures users always have one clear next action.

## Data and user flow

The user flow minimizes branching during first setup, then progressively reveals
complexity only when users opt into advanced paths.

1. Install package dependencies.
2. Run canonical Quickstart configuration.
3. Follow decision tree for profile and variable choices.
4. Run validation checklist.
5. Move to deep dives only for advanced requirements.

This flow standardizes navigation and reduces implicit decisions that often lead
to setup failures.

## Error handling and troubleshooting

Troubleshooting content uses a strict structure to reduce debugging time for new
users. Each issue entry uses **symptom**, **cause**, and **fix**, with commands
users can copy directly.

The first release focuses on common setup failures, including:

- Missing or incorrect region and profile configuration.
- Variable mismatches for optional/experimental fields.
- Permissions and required rights not set before first run.

## Testing and verification

Documentation quality checks focus on correctness, navigability, and execution
confidence for first-time users.

1. Validate internal links and canonical redirects.
2. Verify command snippets are copy-paste runnable.
3. Execute a fresh-project dry run against the new Quickstart flow.
4. Confirm decision tree outcomes map to valid configurations.

Success is a clearer common setup path with fewer manual decisions and lower
onboarding ambiguity.

## Rollout strategy

The rollout performs a full IA rewrite in one coordinated update while
preserving discoverability through migration guidance.

- Publish the new canonical pages in one versioned docs update.
- Add migration map and cross-links from prior entry points.
- Track incoming setup questions to identify any missing guidance.

## Next steps

After approval of this design, create a detailed implementation plan that breaks
the rewrite into concrete file-level edits, validation checks, and review gates.
