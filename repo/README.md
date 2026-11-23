# Repository tooling

Scripts to sign and publish the `[glassfort]` package repository. CI builds
unsigned packages; the maintainer signs and publishes them (D-26 in
[`docs/DECISIONS.md`](../docs/DECISIONS.md)). Signing keys are never
committed.

See [`docs/01-architecture.md`](../docs/01-architecture.md#build-and-publishing-pipeline).

| Script | Purpose |
|---|---|
| `publish` | Sign packages and add them to a repository directory with `repo-add --sign` |
| `vm-test-key` | VM tests only: create a throwaway signing key inside the VM and make pacman trust it |

## publish

```sh
repo/publish [--key KEYID] [--dest DIR] PACKAGE...
```

- Signs every package that has no valid signature by the signing key
  (`--key`, or the first secret key in `$GNUPGHOME`).
- Copies packages and signatures to `DIR` (default
  `/srv/glassfort/repo/x86_64`, the server in
  [`glassfort-mirrorlist`](../components/glassfort-mirrorlist/)) and updates
  the signed database `glassfort.db`. Older versions are removed.
- Checks all packages before changing anything. It refuses to replace a
  published file with different contents (bump `pkgrel` instead) and
  refuses downgrades.
- Uploading to a public server follows once one exists (D-33, D-30).

## VM tests (Phase 1)

Until the real repository key exists, VM tests use a throwaway key that is
created inside the VM and never leaves it (D-26). Inside the test VM, as
root:

```sh
repo/vm-test-key        # refuses to run outside a VM
GNUPGHOME=/var/lib/glassfort/vm-test-gnupg repo/publish out/*.pkg.tar.zst
pacman -S glassfort-mirrorlist
```

Then add `[glassfort]` above `[core]` in `/etc/pacman.conf` (see
[`glassfort-mirrorlist`](../components/glassfort-mirrorlist/README.md)) and
run `pacman -Syu`.
