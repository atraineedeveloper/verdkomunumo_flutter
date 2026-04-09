# Technical Debt

## Usage

This file is not a narrative list. It is the execution backlog for structural improvement work.

Status values:

- `identified`
- `planned`
- `in_progress`
- `blocked`
- `done`

Each item should eventually include:

- owner
- status
- target milestone
- dependencies
- done when

## Priority P0

### 1. Direct Supabase access from UI

- Status: `done`
- Owner: `unassigned`
- Target milestone: `architecture-foundation`
- Dependencies: none

Impact:

- high coupling
- low testability
- duplicated logic
- scattered error handling

Evidence:

- this debt existed in the original MVP structure and has been removed from presentation in the current refactor

Plan:

- introduce repositories per feature
- move queries into `data/`
- expose state through Riverpod

Done when:

- presentation no longer imports or calls Supabase directly
- repository-backed feature flows preserve behavior parity

### 2. Encoding issues in UI strings

- Status: `planned`
- Owner: `unassigned`
- Target milestone: `core-stability`
- Dependencies: none

Impact:

- visible product quality degradation
- risk of content corruption and poor developer experience

Evidence:

- the highest-visibility corrupt strings were fixed during the hardening pass
- a repository-wide encoding policy still needs to be maintained over time

Plan:

- normalize files to UTF-8
- review visible strings
- define an encoding policy

Done when:

- visible strings render correctly across maintained feature areas
- new docs and source files follow a single encoding policy
- legacy text corruption no longer appears in the codebase

### 3. Router is not reactive to auth state changes

- Status: `done`
- Owner: `unassigned`
- Target milestone: `auth-refactor`
- Dependencies: auth state provider

Impact:

- fragile route protection
- inconsistent behavior during login, logout, or session restore

Plan:

- connect `go_router` to observable authentication state
- centralize guards

Done when:

- login, logout, and restored session transitions are reflected by routing without manual screen repair

## Priority P1

### 4. Declared but unused dependencies

- Status: `done`
- Owner: `unassigned`
- Target milestone: `architecture-foundation`
- Dependencies: state management direction

Impact:

- architectural noise
- false sense of standardization

Evidence:

- Riverpod now governs application state in the refactored features

Plan:

- adopt it formally during the refactor or remove it temporarily

Done when:

- dependency list reflects actual architecture choices

### 5. Large screens with multiple responsibilities

- Status: `done`
- Owner: `unassigned`
- Target milestone: `feature-refactors`
- Dependencies: repository extraction, state unification

Impact:

- expensive maintenance
- high regression risk

Evidence:

- the original large screens were split across layered feature modules during the refactor program

Plan:

- split into widgets, providers, and use cases

Done when:

- critical screens are separated by layer and no longer act as combined UI/state-data controllers

### 6. Inconsistent error handling

- Status: `planned`
- Owner: `unassigned`
- Target milestone: `core-stability`
- Dependencies: shared error model

Impact:

- uneven UX
- harder support and debugging

Plan:

- create a shared app error layer
- standardize user-facing messages

Done when:

- critical user flows use a shared error translation approach

## Priority P2

### 7. README previously left at scaffold level

- Status: `done`
- Owner: `unassigned`
- Target milestone: `docs-hardening`
- Dependencies: architecture docs

Plan:

- keep it aligned with real architecture and onboarding needs

Done when:

- onboarding and architecture entry points remain current

### 8. Insufficient coverage on critical flows

- Status: `planned`
- Owner: `unassigned`
- Target milestone: `test-hardening`
- Dependencies: refactored feature boundaries

Plan:

- auth
- feed
- profile
- routing
- repositories and controllers

Done when:

- critical flows have deterministic automated coverage at the appropriate test layer

## Priority P3

### 9. Open source maintainer operations are still new

- Status: `planned`
- Owner: `unassigned`
- Target milestone: `oss-readiness`
- Dependencies: CI and community files

Impact:

- contributor traffic can outgrow manual maintainer workflows
- release and triage quality can become inconsistent

Plan:

- keep CI required on PRs
- add labels and milestone discipline
- start changelog and release notes from the first public release

Done when:

- repository triage and release practices are repeatable and documented

## Rule

Technical debt should not be addressed randomly. It should be paid down in order of architectural impact unless an explicit exception is documented.
