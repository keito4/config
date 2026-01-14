---
description: Run OpenAI Codex review for the current branch
allowed-tools: Bash(git branch:*), Bash(git status:*), Bash(git merge-base:*), Bash(git diff:*), Bash(codex exec:*), Bash(codex status:*)
argument-hint: [base-branch]
---

## Context

- Base branch: $ARGUMENTS
- Current branch: !`git branch --show-current`
- Working tree: !`git status --porcelain`

## Codex review

!`BASE="$ARGUMENTS"; [ -n "$BASE" ] || BASE="origin/main"; codex exec --sandbox read-only "You are acting as a reviewer for a proposed code change made by another engineer. Focus on issues that impact correctness, performance, security, maintainability, or developer experience. Flag only actionable issues introduced by the change. When you flag an issue, provide a short, direct explanation and cite the affected file and line range. Prioritize severe issues and avoid nit-level comments unless they block understanding of the diff. After listing findings, produce an overall correctness verdict ('patch is correct' or 'patch is incorrect') with a concise justification and a confidence score between 0 and 1. Review the current branch against ${BASE}. Use git merge-base to find the merge base, then review the diff from that merge base to HEAD."`
