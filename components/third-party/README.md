# Third-party packages

Packages that Glassfort needs but that only exist in the AUR. They are
reviewed and carried in `[glassfort]` instead of depending on the AUR
(CLAUDE.md §6.6). They keep their upstream licences.

| Package | Upstream | Licence | Reviewed |
|---|---|---|---|
| [`limine-mkinitcpio-hook`](limine-mkinitcpio-hook/) | [limine-entry-tool](https://gitlab.com/Zesko/limine-entry-tool) | GPL-3.0-only | 1.41.0, 2026-11-22 |
| [`limine-snapper-sync`](limine-snapper-sync/) | [limine-snapper-sync](https://gitlab.com/Zesko/limine-snapper-sync) | GPL-3.0-only | 1.33.0, 2026-11-22 |

## Review checklist for updates

1. Read the upstream diff between the old and new tag (Java sources,
   shell scripts, pacman hooks, systemd units).
2. Look for network access, privilege changes and new `bash -c` calls with
   untrusted input.
3. Check that the licence has not changed.
4. Check that the Glassfort patches still apply and are still needed.
5. Update the "Reviewed" column above.
