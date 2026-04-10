# Data And Migrations

## Goal

Define how Supabase-backed schema and data contracts should evolve without destabilizing the application.

See `docs/DB_STANDARDS.md` for enforceable database-level rules.

## Rules

- Schema changes must be deliberate and reviewable.
- App code must not assume undocumented schema behavior.
- Breaking data contract changes require coordination with app changes.

## Source of truth

The database schema, migration history, and data contract expectations should be treated as versioned assets of the repository.

## Migration policy

Every schema change should include:

- a clear reason
- the migration itself
- impact on existing app code
- rollback considerations when applicable
- RLS policy updates when new tables or columns are introduced

## Contract policy

When app code depends on:

- table names
- column names
- joins
- computed fields
- row-level assumptions

those assumptions should be explicit in the corresponding repository or mapper layer.

## Backward compatibility

Avoid changes that require simultaneous unsafe deployment across all environments.

Prefer:

- additive migrations first
- app compatibility during transition
- cleanup after the app no longer depends on legacy fields

## RLS policy expectations

- Every new table must enable RLS and define policies.
- Policies must cover all CRUD operations or explicitly document why not.
- `SECURITY DEFINER` functions must set `search_path = public`.

## Testing expectations

- Schema changes should include pgTAP tests in `supabase/tests`.
- RLS changes must update or add policy tests.
- Column or constraint changes must update contract tests.

## Idempotency and concurrency

- For event-driven inserts (notifications, deliveries), use unique constraints.
- Prefer `ON CONFLICT DO NOTHING` for de-duplication.

## Rollback guidance

- Document how to revert a change even if the migration is forward-only.
- Use feature flags or staged column migration to avoid hard rollbacks.

## Environments

At minimum, the team should distinguish:

- local development
- preview or staging
- production

Environment-specific configuration must not leak into presentation code.

## Seeds and fixtures

Where practical, representative local seed data should exist for:

- authentication flows
- feed data
- profile data
- notifications

This reduces guesswork and improves deterministic testing.
