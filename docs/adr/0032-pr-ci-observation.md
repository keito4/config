# ADR 0032: Produce a CI result for every pull request

## Status

Accepted, 2026-11-03.

## Context

The fallback must verify a successful CI run for the current PR head. A
workflow-level path filter prevents any CI observation for documentation-only
changes, leaving a strict fallback waiting until its deadline.

## Decision

Remove only the `pull_request.paths` filter from `ci.yml`. Retain its branches,
push filters, schedule, permissions, job conditions and commands. The existing
change-detection job still decides which application checks need execution.
The Quality Gate reports the existing policy for that observed change set.

## Consequences

Every PR receives a CI observation, including documentation-only changes.
Lightweight detection and reporting jobs run more often; unchanged application
checks remain skipped under their existing conditions. A missing or unreadable
CI run never becomes success merely because no check was found. This prepares
the strict fallback change without weakening application tests or coverage.
