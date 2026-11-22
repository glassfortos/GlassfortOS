# limine-mkinitcpio-hook

Installs kernels and initramfs images for the Limine bootloader and keeps
`limine.conf` up to date through pacman hooks. Also provides
`limine-enroll-config`, which embeds the config checksum for Secure Boot
(see [`docs/02-system.md`](../../../docs/02-system.md#secure-boot-with-limine)).

Upstream: <https://gitlab.com/Zesko/limine-entry-tool> (author: Zesko).
Licence: GPL-3.0 (the upstream `LICENSE` file has no "or later" notice, so the
package is declared as GPL-3.0-only).

Built from the upstream tag with GraalVM Community Edition (official release
from `graalvm/graalvm-ce-builds`, pinned by SHA-256) because the tool is a
Java program compiled to a native binary. GraalVM is only used at build time.

## Review (1.41.0, 2026-11-22)

- No network access in the Java sources or shell scripts.
- External commands are started with `ProcessBuilder("bash", "-c", …)`.
  The logger call built its shell command from log messages that can
  contain command output → patched (see below). The remaining `bash -c`
  calls use fixed commands from the tool's own config.

## Glassfort changes

| Change | Why |
|---|---|
| `logger-no-shell.patch` | Call `logger` directly instead of via `bash -c`, so log messages are never interpreted by a shell (the tool runs as root). To be reported upstream. |
| `/usr/local/bin/mkinitcpio` wrapper removed | Packages must not install into `/usr/local`; the wrapper also asks an interactive question, which can hang non-interactive callers. Use `limine-mkinitcpio` or `limine-update`. |
| `x86_64` only | Glassfort is x86_64 only (D-01). |
