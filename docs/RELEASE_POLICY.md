# Release Policy

## Goal

Define the minimum operational discipline for shipping a stable open source application.

## Versioning

The project should move toward semantic versioning for tagged releases:

- major for breaking changes
- minor for backward-compatible features
- patch for fixes and internal improvements that do not break contracts

## Release expectations

Before a release:

- critical checks should pass
- major known regressions should be documented or fixed
- architecture-breaking temporary exceptions should be visible

## Changelog discipline

Releases should communicate:

- user-visible changes
- developer-facing breaking changes
- migration notes when needed

## Deprecation policy

When removing or replacing important internal contracts:

- document the replacement path
- allow a reasonable transition window when possible
- avoid silent breakage

## Compatibility mindset

Open source users should not need tribal knowledge to understand:

- what changed
- whether it is safe to upgrade
- whether any migration work is required
