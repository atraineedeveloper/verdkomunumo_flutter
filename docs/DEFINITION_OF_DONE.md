# Definition Of Done

A change is not done just because it "works on my machine".

## Required criteria

- It follows `docs/ARCHITECTURE.md`.
- It does not increase direct coupling between UI and backend.
- It handles `loading`, `success`, `empty`, and `error` explicitly when applicable.
- It does not leave broken text caused by encoding issues.
- It preserves navigation and authentication consistency.
- It has tests or an explicit justification.
- It does not introduce new TODOs without registering them in `docs/TECH_DEBT.md`.
- It satisfies the relevant quality gates from `docs/ENGINEERING_STANDARDS.md`.

## For presentation changes

- Widgets are small or clearly split by responsibility.
- No direct remote queries.
- No large `setState`-driven flows when the state already belongs to a stable feature.
- Basic accessibility is preserved.

## For application or state changes

- State is observable and testable.
- Intermediate states are defined.
- Side effects are concentrated in providers, notifiers, or use cases.

## For data changes

- Repositories encapsulate the external provider.
- DTOs and mappers are explicit.
- Error handling is consistent.
- Data contract impact is documented when applicable.

## For architecture changes

- An ADR is created or updated.
- The impact on current features is documented.

## Minimum technical validation

Before closing a change, these should ideally be executed:

- `flutter analyze`
- `flutter test`

If they cannot be executed, that must be stated in the work summary.

## Merge readiness

The change is not merge-ready if:

- critical checks were skipped without explanation
- new architecture violations were introduced
- new debt was added without tracking
- the rollback story is unclear for risky changes
