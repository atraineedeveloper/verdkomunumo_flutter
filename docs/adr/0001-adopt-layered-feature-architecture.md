# ADR 0001: Adopt Layered Feature Architecture

## Status

Accepted

## Context

The current project concentrates UI, state, and Supabase access inside screens and widgets. That accelerated the MVP, but it now makes testing, maintenance, and product evolution harder.

## Decision

Adopt a feature-oriented architecture with these layers:

- `presentation`
- `application`
- `domain`
- `data`

Each feature must be migrated progressively toward this structure.

## Consequences

Positive:

- lower coupling
- better testability
- better isolation of changes

Costs:

- more files
- more design discipline
- mandatory incremental refactoring

## Notes

This will not be a big bang migration. Adoption will happen feature by feature.
