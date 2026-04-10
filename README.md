# Verdkomunumo Flutter

Flutter application for Verdkomunumo, a social network for the Esperanto community.

This repository is in a stabilization and technical debt reduction phase. Before adding major new features, the project is governed by the documentation in `docs/`.

## Core documentation

- `docs/ARCHITECTURE.md`: target architecture, layer rules, boundaries, and allowed dependencies.
- `docs/CONTRIBUTING.md`: contribution workflow, review expectations, and PR standards.
- `docs/DEFINITION_OF_DONE.md`: minimum criteria required to consider a change complete and merge-ready.
- `docs/ENGINEERING_STANDARDS.md`: quality gates, testing expectations, and exceptions process.
- `docs/TECH_DEBT.md`: prioritized structural backlog with milestones and exit criteria.
- `docs/PLAYBOOK.md`: fast implementation guidance without losing architectural discipline.
- `docs/DATA_AND_MIGRATIONS.md`: schema evolution, migration, and environment rules for Supabase-backed changes.
- `docs/RELEASE_POLICY.md`: versioning, changelog, deprecation, and upgrade expectations.
- `docs/ARCHITECTURE_REVIEW.md`: current architectural assessment and remaining release-grade gaps.
- `docs/adr/`: architectural decision records.

## Current state

The project already includes functional UI for:

- authentication
- feed
- profile
- search
- notifications
- settings

The large architecture migration is complete. The project now uses a layered feature structure with Riverpod-governed application state and repositories around Supabase access.

The next phase is hardening for public maintenance quality: stronger tests, shared error handling, release discipline, and contributor operations.

## Operating rule

Major new work should not be added without complying with:

1. `docs/ARCHITECTURE.md`
2. `docs/DEFINITION_OF_DONE.md`
3. `docs/ENGINEERING_STANDARDS.md`
4. the priorities defined in `docs/TECH_DEBT.md`

## Running the app

Supabase `dart-define` values are required:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=... `
  --dart-define=SUPABASE_ANON_KEY=...
```

For local VS Code run and debug, this repository is configured to read credentials from `.env.flutter` through `--dart-define-from-file`.

1. Open [.env.flutter](/c:/Users/DELL/DevProjects/verdkomunumo_flutter/.env.flutter)
2. Set:
   `SUPABASE_URL=...`
   `SUPABASE_ANON_KEY=...`
3. Run any launch profile from [.vscode/launch.json](/c:/Users/DELL/DevProjects/verdkomunumo_flutter/.vscode/launch.json)

An example file is available at [.env.flutter.example](/c:/Users/DELL/DevProjects/verdkomunumo_flutter/.env.flutter.example).

## Validation

- `flutter analyze`
- `flutter test`

Both commands were validated successfully on 2026-04-09 with the local Flutter toolchain.

## Open source readiness

The repository now includes:

- `LICENSE`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- GitHub issue templates
- a pull request template
- a CI workflow for formatting, analysis, and tests

Contributors are expected to read `docs/ARCHITECTURE.md`, `docs/CONTRIBUTING.md`, and `docs/ENGINEERING_STANDARDS.md` before opening non-trivial changes.
