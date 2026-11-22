# limine-snapper-sync

Adds Snapper snapshots of `/` to the Limine boot menu, so a broken update can
be rolled back from the boot menu
(see [`docs/02-system.md`](../../../docs/02-system.md#snapshots)).

Upstream: <https://gitlab.com/Zesko/limine-snapper-sync> (author: Zesko).
Licence: GPL-3.0 (the upstream `LICENSE` file has no "or later" notice, so the
package is declared as GPL-3.0-only).

Built from the upstream tag with GraalVM Community Edition (official release,
pinned by SHA-256), only at build time.

## Review (1.33.0, 2026-11-22)

- No network access in the Java sources or shell scripts.
- Snapshot descriptions are XML-escaped before they are written to
  Snapper's `info.xml`.
- The logger call built a `bash -c` command from log messages that can
  contain command output → patched (see below).
- Note for `glassfort-helper` (Phase 3): snapshot descriptions should still
  be limited to a safe character set, because they end up in `limine.conf`
  labels.

## Glassfort changes

| Change | Why |
|---|---|
| `logger-no-shell.patch` | Call `logger` directly instead of via `bash -c`, so log messages are never interpreted by a shell (the tool runs as root). To be reported upstream. |
| `x86_64` only | Glassfort is x86_64 only (D-01). |
| Optional `b3sum`/`xxhash`/dracut entries dropped | Not used by Glassfort (mkinitcpio, BLAKE2B hashes in `limine.conf`). |
