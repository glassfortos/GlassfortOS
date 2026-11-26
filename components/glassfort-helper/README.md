# glassfort-helper

Glassfort's privileged helper: a small Rust service on the system bus that
runs as root and performs a fixed set of typed, validated actions, each one
authorised with polkit for the caller (docs/02, docs/05). It has no shell
and no generic "run this" method.

Phase 2 (D-44) has one action, for the Time Machine:

| Method | polkit action | Default |
|---|---|---|
| `RestoreSnapshot(u id)` | `org.glassfort.helper.restore-snapshot` | admin password, kept for a few minutes (`auth_admin_keep`); refused for inactive and remote sessions |

`RestoreSnapshot` runs `limine-snapper-sync --restore <id> --non-interactive`
(Glassfort patch, `components/third-party/limine-snapper-sync`): the root
subvolume is replaced by a writable copy of the snapshot, the previous
state is kept as a backup snapshot, and the boot menu is rewritten. It does
not reboot; the caller asks the user. The call returns when the restore has
finished (seconds; limit 15 minutes), so clients need a long D-Bus timeout.
Only one action runs at a time.

Property `Version` (string) tells clients what the helper offers.

## Files

| File | Installed as |
|---|---|
| `main.rs`, `restore.rs` | `/usr/lib/glassfort-helper/glassfort-helper` |
| `org.glassfort.Helper1.conf` | D-Bus policy: only root owns the name; anyone may call (polkit decides) |
| `org.glassfort.Helper1.service` | D-Bus activation → `glassfort-helper.service` |
| `glassfort-helper.service` | systemd unit; the service exits after 5 idle minutes |
| `org.glassfort.helper.policy` | polkit actions |

## Audit log

Every request is logged to the journal with the caller's user id and the
outcome:

```sh
journalctl -u glassfort-helper
```

## Try it

```sh
busctl call org.glassfort.Helper1 /org/glassfort/Helper1 \
    org.glassfort.Helper1 RestoreSnapshot u 42 --timeout=20min
```

## Checks

`cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` (also run
by the PKGBUILD's `check()`).
