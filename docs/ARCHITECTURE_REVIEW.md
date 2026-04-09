# Architecture Review

## Date

2026-04-09

## Scope

Post-refactor review after migrating the app to a layered, Riverpod-governed feature structure and removing direct Supabase access from presentation.

## Current assessment

The project is now materially stronger than the original MVP baseline.

Major improvements already completed:

- reactive auth and routing
- feature-level repository boundaries
- Riverpod-based application state across critical features
- removal of direct Supabase calls from presentation
- improved documentation and contribution rules
- green `flutter analyze` and `flutter test` validation

This is now a viable open source base, but it is not yet at a mature release engineering standard.

## What is solid now

### 1. Architectural direction

The repository has a clear target architecture and that target is now reflected in code, not only in docs.

### 2. Feature boundaries

Auth, feed, profile, settings, notifications, search, post detail, and post interactions now follow a consistent `domain` / `data` / `application` / `presentation` split.

### 3. UI responsibility

Presentation is significantly thinner. Business logic and persistence concerns are no longer spread across screens and shared widgets.

### 4. Validation baseline

Static analysis and automated tests run successfully with the local Flutter toolchain and can now be enforced in CI.

## Residual debt

### 1. Shared error model is still missing

The app has better separation, but error translation is still feature-local and not yet standardized across the product.

Impact:

- inconsistent user-facing failure messages
- duplicated error mapping logic
- weaker observability for production failures

Recommended next move:

- introduce a shared app failure model in `lib/core/`
- define a consistent translation path from backend exceptions to app-level failures

### 2. Test depth is still below a release-grade bar

The repository has a healthier test baseline, but coverage is still selective rather than comprehensive.

Impact:

- limited protection against regressions in async state transitions
- insufficient coverage of repository and mapping behavior
- critical flows are still under-tested at integration level

Recommended next move:

- add provider/controller tests for auth, feed, and profile
- add repository tests for Supabase mapping and failure translation
- add a small set of higher-value widget or integration tests for critical user paths

### 3. Analyzer policy is still light

`analysis_options.yaml` still relies on the default Flutter lint profile with minimal project-specific tightening.

Impact:

- some architectural and consistency issues can still slip through review
- enforcement remains more social than automated

Recommended next move:

- add stronger lint rules where the team agrees
- introduce boundary checks or custom import constraints if the repo grows

### 4. Release and maintainer operations are young

The repository now has OSS governance files, but maintainer processes are still early-stage.

Impact:

- release discipline depends on maintainers manually following docs
- support and triage practices are not yet battle-tested

Recommended next move:

- define milestone discipline
- start a changelog process from the first public release onward
- add labels and issue triage automation once the repo opens to external traffic

## Release readiness verdict

### Ready for

- public code visibility
- contributor onboarding
- controlled open source collaboration
- iterative architectural improvement

### Not fully ready for

- rapid, high-volume external contribution
- strict semantic-versioned releases with long-lived support expectations
- high-confidence regression control on all critical flows

## Recommended next backlog

1. Introduce a shared error model and UI-facing error policy.
2. Add controller and repository tests for critical paths.
3. Tighten analyzer and formatting enforcement further.
4. Start release discipline with tags, changelog, and milestone-based planning.
