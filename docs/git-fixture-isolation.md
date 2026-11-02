# Git fixture isolation

Tests that run Git in temporary repositories must remove the repository-local
environment variables reported by `git rev-parse --local-env-vars`. A fixed list
of four variables misses `GIT_COMMON_DIR` and `GIT_OBJECT_DIRECTORY`.

For example, an inherited `GIT_COMMON_DIR` can make `git init --bare` update the
caller's config, even when its destination is a separate temporary directory.
Removing all repository-local variables follows the
[Git hook guidance](https://git-scm.com/docs/githooks#_description). Other process
settings and explicit non-Git fixture options remain available.

Ordinary linked-worktree commit hooks also export `GIT_DIR`. Python launcher
regressions must clear it before initializing a fixture or invoking its hooks.
Otherwise `git init` can change the parent's `core.bare` while the tests pass,
leaving subsequent operations unable to use the parent working tree.

Run the regression with:

```sh
npm test -- --runTestsByPath test/git-fixture-isolation.test.js
```

It runs the real JavaScript and Python fixture suites with Git paths pointing to
a disposable linked worktree and verifies the parent's config, index, refs, and
status are unchanged. It covers both ordinary hook variables and explicit common
directory / object directory overrides.
