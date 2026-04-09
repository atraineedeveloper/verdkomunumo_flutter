# Data And Migrations

## Goal

Define how Supabase-backed schema and data contracts should evolve without destabilizing the application.

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
