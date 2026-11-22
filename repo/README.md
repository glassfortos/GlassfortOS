# Repository tooling

Scripts to build, sign and publish the `[glassfort]` package repository
(for example `repo/publish`, which runs `repo-add --sign`). CI builds
unsigned packages; the maintainer signs and publishes them. Signing keys
are never committed.

See [`docs/01-architecture.md`](../docs/01-architecture.md#build-and-publishing-pipeline).
