# Engineering Standards

## Goal

Define enforceable quality gates for code that is expected to survive scale, contributors, and long-term maintenance.

## Merge gates

The target standard for merge-ready code is:

- architecture rules respected
- tests added or updated where behavior changed
- static analysis passing
- no new critical debt introduced without tracking
- risk documented for non-trivial changes

## Required checks

For a mature CI setup, the repository should require:

- `flutter analyze`
- `flutter test`
- formatting validation
- any future architecture or import boundary checks
- migration linting (idempotency + RLS)
- database contract review for schema changes
- `supabase test db` for schema or policy changes when available

If a check cannot run in the current environment:

- say so explicitly
- explain why
- state the residual risk

## Test expectations

### Domain

- pure unit tests
- edge cases covered for business rules

### Application

- use case tests
- async state transition tests
- error path coverage for critical flows

### Data

- mapper tests
- repository behavior tests
- translation of backend errors into app-level failures

### Presentation

- widget tests for loading, success, empty, and error states where relevant
- navigation behavior tests for critical flows

## Review standards

Review should reject code that:

- adds architectural coupling without justification
- introduces behavior without test coverage in critical paths
- hides complexity inside UI widgets
- leaves naming or responsibilities ambiguous
- bypasses documented architecture for convenience

## Exceptions process

Exceptions are allowed only when:

- the constraint is explicitly named
- the reason is concrete
- the scope is narrow
- the follow-up debt is tracked in `docs/TECH_DEBT.md`

## Documentation standards

Public-facing docs must be:

- current
- consistent with the codebase
- free of visible encoding corruption
- precise enough to guide contributors without tribal knowledge
