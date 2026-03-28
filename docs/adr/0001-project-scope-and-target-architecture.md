# ADR 0001: Project Scope and Target Architecture

- Status: Accepted
- Date: 2026-03-28
- Owners: Repository maintainers

## Context

Recent analysis identified a mismatch between external project narrative (price intelligence data warehouse) and the actual codebase (containerized stress workload generator).

This mismatch creates delivery risk and weakens production/recruiter signaling because expectations do not match implementation.

## Decision

The repository is formally scoped as a chaos workload utility centered on `stress-ng` profile execution.

Target architecture remains intentionally small and production-oriented:
1. Containerized runner (`Containerfile`)
2. Parameterized launcher (`run.sh`)
3. Template-driven workload specs (`*.conf.template`)
4. CI image build and publish workflow (`.github/workflows/build.yaml`)

## Consequences

Positive:
- Aligns implementation, documentation, and ownership boundaries.
- Enables focused production-hardening roadmap without scope confusion.
- Improves resume credibility by clearly stating what the project does.

Trade-offs:
- Data engineering claims must move to a separate repo or future initiative.
- Existing messaging that implies DWH functionality must be corrected.

## Follow-up Actions

P0 follow-ups (separate changes):
1. Harden shell runtime behavior and deterministic defaults.
2. Add CI quality/security gates.
3. Add operational runbook and metrics expectations.
