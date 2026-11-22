# glassfort-settings

All Glassfort system defaults: snapper configs, Limine configuration,
sysctl, firewalld zones, AppArmor, `pacman.conf` (repository order), zram
and the keyd configuration for the Copilot key.

**Status:** Phase 0 – empty package. It exists so that CI can prove a
package builds in a clean chroot. The configuration follows in Phase 1
(see [`docs/09-roadmap.md`](../../docs/09-roadmap.md) and
[`docs/02-system.md`](../../docs/02-system.md)).

## Build

```sh
cd components/glassfort-settings
extra-x86_64-build      # clean chroot (devtools)
# or, for a quick local check:
makepkg --cleanbuild
```
