# Database Standards

## Goal

Define enforceable, reviewable database standards that protect data integrity,
privacy, and performance at scale.

## Ownership

- The `supabase/` directory in this repository is the source of truth.
- All schema changes must be made through migrations.
- Direct edits to production schemas are forbidden.

## Naming

- Tables: plural, snake_case (e.g. `notification_devices`).
- Columns: snake_case; no ambiguous abbreviations.
- Indexes: `idx_<table>_<columns>` (e.g. `idx_notifications_user_created`).
- Triggers: `on_<event>_<table>` (e.g. `on_comment_notification`).
- Functions: `handle_<domain>` or `queue_<domain>`.

## RLS Policy Rules

- Every table must have RLS enabled.
- Every table must have explicit `SELECT`, `INSERT`, `UPDATE`, and `DELETE` policies
  or documented reasons for omission.
- RLS policies must use `auth.uid()` or explicit role checks; no implicit trust.
- `SECURITY DEFINER` functions must set `search_path = public`.

## Migration Rules

- Every migration must be **forward-only** and **idempotent**.
  - Use `IF NOT EXISTS` and safe `DROP ... IF EXISTS`.
- Additive changes first (new columns, new tables).
- Breaking changes must be staged:
  1) add new column
  2) backfill / dual-write
  3) migrate app usage
  4) remove old column in a later migration
- Every migration should include:
  - rationale
  - expected impact
  - rollback notes

## Data Integrity

- Prefer `CHECK` constraints for domain validation.
- Use foreign keys with explicit `ON DELETE` behavior.
- Use unique constraints for idempotency and de-duplication.
- For counters, ensure updates are atomic and derived from triggers where possible.

## Security And Privacy

- Classify sensitive columns (emails, device tokens, IPs) as protected data.
- Avoid exposing protected data in public views or client-facing RPCs.
- Prefer server-side filtering to client-side filtering when privacy is involved.
- For security-critical functions, use `SECURITY DEFINER` plus explicit role checks.
- Deny by default: start with no policies, then add explicit access policies.

## Schema Design

- Use `UUID` primary keys consistently for user-facing entities.
- Keep denormalized counters consistent with source-of-truth tables.
- Store timestamps in UTC (`TIMESTAMPTZ`) with `created_at` and `updated_at`.
- For soft deletion, use `deleted_at` and keep policies consistent with visibility.

## Performance Standards

- Add indexes for every access pattern used in app queries.
- Index foreign keys used in joins.
- Use `GIN` indexes for full-text and arrays.
- Avoid unbounded `SELECT *` in production paths; restrict to fields used.
- If a wide read is needed, document it and index accordingly.

## Observability

- Add audit columns (`created_at`, `updated_at`) on core tables.
- For delivery queues, include `status`, `error`, and `sent_at`.
- Use idempotency keys to avoid duplicates where concurrency exists.

## Testing Expectations

- Add or update `supabase/tests` pgTAP tests for schema and RLS changes.
- RLS tests must cover every table with public access.
- Contract tests should assert required columns and constraints.

## Operations

- Define retention rules for notifications, logs, and deliveries.
- Document any background cleanup job required by the schema.
- Backups must be enabled for production with a defined restore procedure.

## Environments

- Local, staging, production must be kept in migration parity.
- Seed data should be safe, synthetic, and deterministic.

## Review Checklist

- RLS enabled and policies present?
- Migration idempotent and staged?
- Indexes for new query paths?
- Backfill or default values accounted for?
- Rollback note included?
