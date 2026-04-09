# ADR 0002: Encapsulate Supabase Behind Repositories

## Status

Accepted

## Context

Supabase is currently spread across the presentation layer. That makes the UI fragile, hard to mock, and prone to duplicated data access rules.

## Decision

All Supabase access must live in `data/`, behind repositories defined by domain or application contracts.

## Consequences

Positive:

- presentation is decoupled from the backend
- better testing
- centralized error handling

Negative:

- initial implementation cost
- need for mappers and explicit contracts

## Notes

Legacy code is temporarily allowed during the migration, but no new direct Supabase calls should be added to widgets.
