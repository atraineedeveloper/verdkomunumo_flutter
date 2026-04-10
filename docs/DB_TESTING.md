# Database Testing

## Goal

Provide a minimal, repeatable way to validate database contracts and RLS
policies before changes land in main.

## Scope

- pgTAP tests live in `supabase/tests`.
- Tests focus on RLS coverage and schema contracts for critical tables.

## Local Runbook

1. Start the local Supabase stack.
2. Ensure migrations and seeds are applied.
3. Run `supabase test db`.

If local Supabase is not available, call that out in the PR and document the
residual risk.

## Expectations

- Every schema change should update or add pgTAP tests.
- Policy changes must include explicit RLS coverage.
- Failing tests block merge until resolved or explicitly waived.
