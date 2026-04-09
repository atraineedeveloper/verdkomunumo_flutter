# Architecture

## Goal

Turn Verdkomunumo Flutter into a maintainable application with explicit layer rules, controlled dependencies, better testability, lower coupling to Supabase, and governance strong enough for long-term open source development.

## Principles

- UI must not access Supabase directly.
- Business logic must not live inside widgets.
- Each feature must have clear boundaries.
- State must flow in one direction.
- Error handling must be consistent and visible.
- Architecture decisions must be recorded as ADRs.
- Rules must be enforceable, not aspirational only.

## Target architecture

Each feature should evolve toward this structure:

```text
lib/
  app/
    bootstrap/
    routing/
    theme/
  core/
    error/
    result/
    config/
    utils/
    widgets/
  features/
    feed/
      domain/
      application/
      data/
      presentation/
    auth/
      domain/
      application/
      data/
      presentation/
```

## Layer responsibilities

### Presentation

Responsibilities:

- widgets
- screens
- UI providers
- mapping state to interface
- user interactions

Not allowed:

- direct Supabase queries
- persistent business rules
- complex data transformations

### Application

Responsibilities:

- use cases
- coordination across repositories
- flow rules
- async state and side effects

Not allowed:

- widgets
- concrete HTTP, Supabase, or storage details

### Domain

Responsibilities:

- entities
- value objects
- repository contracts
- pure business rules

This should be the most stable layer.

### Data

Responsibilities:

- repository implementations
- remote and local data sources
- DTOs and mappers
- concrete adaptation to Supabase

Not allowed:

- dependencies on widgets or `BuildContext`

## Dependency rules

Allowed:

- `presentation -> application`
- `presentation -> domain`
- `application -> domain`
- `data -> domain`
- `app -> core`
- `features -> core`

Not allowed:

- `presentation -> data`
- `presentation -> Supabase`
- `domain -> Flutter UI`
- `domain -> Supabase`
- arbitrary cross-feature dependencies

## Boundary enforcement

Architecture without enforcement degrades quickly. The repository should move toward these safeguards:

- Folder structure must mirror architectural layers.
- Imports that bypass allowed dependency directions should fail review.
- Repeated violations should be converted into lint rules or automated checks.
- Shared code must live in `core/` only when it is genuinely cross-feature and stable.
- Feature-to-feature imports are forbidden unless documented in an ADR.

Until automated enforcement exists, every refactor and PR review must validate:

- no new `Supabase.instance.client` usage in presentation
- no new cross-feature coupling without documentation
- no repository implementation imported directly into screens or widgets

## Feature ownership model

Each feature should have explicit ownership boundaries:

- `domain/` defines contracts and invariants
- `data/` implements external integration
- `application/` coordinates flows and state transitions
- `presentation/` renders and forwards events

When a change spans multiple features:

- keep the integration surface narrow
- prefer contracts in `domain/` over direct imports across features
- record non-obvious coupling in an ADR

## State

Target strategy:

- Riverpod is the official solution for state management and dependency injection.
- Async state should be standardized with `AsyncValue` or equivalent wrappers.
- Feature state should be exposed from `application/presentation`, not from oversized stateful widgets.

Transition:

- Temporary coexistence with `StatefulWidget` is acceptable.
- All new code must avoid increasing the current level of coupling.

## Navigation

- `go_router` remains the routing solution.
- Authentication guards must react to session changes.
- Protected routes must depend on observable state, not isolated checks.
- Route names and paths should be centralized.
- Navigation side effects should not be hidden inside low-level data code.

## Data and backend

- Supabase must be encapsulated behind clients and repositories.
- No screen should build SQL-like queries.
- Repeated table and column names should be centralized.
- Every remote response must be mapped to app-controlled models.
- Schema evolution, migrations, and environments are governed by `docs/DATA_AND_MIGRATIONS.md`.

## Errors

Every async flow must handle:

- loading
- success
- empty
- recoverable error
- non-recoverable error

Rules:

- Do not expose raw exceptions directly to users.
- Screens should not decide backend error formatting on their own.
- Repositories should translate technical errors into domain or app failures.
- User-facing messages should be intentional, consistent, and reviewable.

## Testing

Target by layer:

- `domain`: unit tests
- `application`: unit tests
- `data`: mapper and repository tests
- `presentation`: widget tests for critical states

Minimum expectations:

- every bug fix should include a test or an explicit justification
- every critical feature refactor should leave coverage better than before
- merge-critical behavior must be protected by CI over time

Quality gates are defined in `docs/ENGINEERING_STANDARDS.md`.

## Refactor order

Recommended order:

1. auth
2. routing and auth guard
3. feed
4. profile
5. settings
6. notifications
7. search

## Forbidden antipatterns

- `Supabase.instance.client` inside screens or widgets
- `BuildContext` usage inside repositories
- widgets over roughly 250 to 300 lines without strong justification
- mixing remote DTOs and domain entities without separation
- duplicating business rules across screens
- adding dependencies without an ADR or technical justification
