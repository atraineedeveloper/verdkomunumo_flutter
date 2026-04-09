# Contributing

## Goal

This repository is maintained with architecture discipline, not opportunistic changes.

Every contribution must:

- reduce technical debt or at least avoid increasing it
- follow `docs/ARCHITECTURE.md`
- satisfy `docs/DEFINITION_OF_DONE.md`
- satisfy `docs/ENGINEERING_STANDARDS.md`

## Workflow

1. Read `docs/ARCHITECTURE.md`.
2. Check `docs/TECH_DEBT.md` if the change touches known debt.
3. If the decision changes architecture, create or update an ADR.
4. Implement the change by layer.
5. Add or adjust tests.
6. Run analysis and tests.
7. Perform a technical self-review before closing.

## Code rules

- Do not introduce direct Supabase access in presentation.
- Do not mix UI, state, and persistence in the same file when it can be avoided.
- Prefer small files with clear responsibilities.
- Names must reflect the real role of the artifact: `repository`, `provider`, `use_case`, `screen`, `mapper`.
- Avoid obvious comments; comment only non-trivial decisions.

## Change structure

For a new feature or meaningful refactor:

- create domain contracts
- create a repository or data source when needed
- expose state via Riverpod
- keep the screen focused on rendering and user events

## Error handling

- Do not interpolate raw backend exceptions into end-user UI.
- Centralize user-facing error messages where repetition appears.
- If an operation fails, the UI must remain in a consistent state.

## Minimum testing by change type

- Simple visual change: widget test if behavior changed.
- State refactor: unit tests for the provider or notifier.
- Repository change: mapper and happy-path/error-path tests.
- Bug fix: a test that reproduces the bug.

## Branch and PR expectations

- Keep PRs small enough to review coherently.
- Separate architectural refactors from unrelated visual cleanup when possible.
- Large migrations should be split into staged PRs.
- Every PR must describe risk, validation, and rollback considerations.

## Self-review checklist

- The change reduces coupling or at least does not increase it.
- There are no new direct Supabase calls from widgets.
- Loading, error, and empty states are covered.
- Naming is consistent.
- There is a test or a valid technical reason not to add one.
- The change does not leave broken strings or encoding issues behind.
- The change does not violate documented layer boundaries.

## Pull requests

The PR summary should include:

- what changed
- why it changed
- the main risk
- which technical debt it reduces or what new debt it introduces
- which tests were executed
- whether any standards were deferred and why

## Maintainer review criteria

A PR should be sent back for revision if it:

- adds new architecture violations
- mixes unrelated concerns
- weakens test protection on critical flows
- introduces undocumented coupling
- leaves debt behind without tracking it
