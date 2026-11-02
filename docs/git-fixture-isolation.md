# Git fixture isolation

Tests that run Git in temporary repositories must remove the repository-local
environment variables reported by `git rev-parse --local-env-vars`. A fixed list
of four variables misses `GIT_COMMON_DIR` and `GIT_OBJECT_DIRECTORY`.

For example, an inherited `GIT_COMMON_DIR` can make `git init --bare` update the
caller's config, even when its destination is a separate temporary directory.
Removing all repository-local variables follows the
[Git hook guidance](https://git-scm.com/docs/githooks#_description). Other process
settings and explicit non-Git fixture options remain available.

Run the regression with:

```sh
npm test -- --runTestsByPath test/git-fixture-isolation.test.js
```

It runs the real fixture suites with Git paths pointing to a disposable linked
worktree and verifies the parent's config, index, refs, and status are unchanged.
The regression establishes this corruption path; it does not establish where an
unexpected variable originated in a previous shell or hook execution.
