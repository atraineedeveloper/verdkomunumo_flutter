# ADR 0003: Standardize State With Riverpod

## Status

Accepted

## Context

The project declares Riverpod as a dependency, but current state is still managed mainly through `StatefulWidget` and `setState`. That leads to large local state containers and makes flows harder to share and test.

## Decision

Riverpod will be the official mechanism for:

- dependency injection
- state management
- orchestration of async use cases

## Consequences

Positive:

- consistent state handling
- better composition
- higher testability

Risks:

- temporary coexistence with the current approach
- need for gradual migration

## Notes

The priority is to migrate critical features before standardizing the rest.
