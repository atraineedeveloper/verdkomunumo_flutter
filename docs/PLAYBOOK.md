# Playbook

## Goal

Allow fast development without falling into uncontrolled vibe coding.

## Main rule

Speed is welcome. Architectural improvisation is not.

## Before touching code

Answer these questions:

1. Which layer should own this change.
2. Which new dependency does it introduce.
3. How will it be tested.
4. Which debt does it reduce or increase.

If there is no clear answer, the change is not ready to implement.

## Mental template for any change

### If it is UI

- the screen renders
- the provider coordinates
- the use case decides
- the repository fetches or persists

### If it is backend integration

- the data source talks to Supabase
- the repository translates
- the app consumes contracts, not the raw SDK

## Pace rules

- make small and reversible changes
- prefer refactoring by feature, not a big bang rewrite
- leave the code slightly better with every step
- do not open multiple architecture migrations at the same time

## Recommended operating prompt

When working with agents or assistants, use instructions like:

```text
Refactor this feature according to docs/ARCHITECTURE.md.
Do not use Supabase in presentation.
Move logic into application/data.
Add minimum tests.
Do not add new features.
Do not leave TODOs untracked.
```

## Decision filter for fast implementation

If a fast shortcut:

- increases coupling
- hides debt
- weakens tests
- blurs feature boundaries
- adds undocumented behavior

then it is not an acceptable shortcut.

## What not to do

- rewrite everything at once
- move files without a clear reason
- mix visual fixes with large architectural changes without separation
- mark work as done without minimum technical validation

## Recommended refactor cadence

1. stabilize contracts
2. extract the data layer
3. introduce unified state
4. simplify presentation
5. add tests
6. clean residual debt
