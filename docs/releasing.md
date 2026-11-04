# Release workflow

## Branch flow

The repository includes a gix configuration for main, develop, feature, bugfix, hotfix and release branches.

~~~sh
gix doctor
gix feature start bilingual-template
gix feature finish
~~~

Use gix for version calculation and branch flow rather than maintaining custom git-flow shell scripts.

## Changelog

Use Conventional Commits such as feat:, fix:, docs:, refactor: and perf:. Generate release notes with:

~~~sh
px changelog
px changelog --version v1.2.0 --dry-run
~~~

Non-conventional subjects are skipped instead of being guessed.

## Version, tag and push

gix owns semantic version bumping:

~~~sh
gix version bump patch --dry-run
gix version bump minor
~~~

After reviewing and committing the changelog, create an annotated or signed tag:

~~~sh
px tag v1.2.0 --sign
~~~

The tag command refuses a dirty working tree. Push the current branch and, only when requested, tags:

~~~sh
px push
px push --tags
~~~

Build commands never commit, tag, push or create releases implicitly.
