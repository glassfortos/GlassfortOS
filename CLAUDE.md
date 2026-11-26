# CLAUDE.md – Glassfort

**Glassfort** is an Arch-based Linux distribution: Windows-style usability, a macOS-inspired glass design, secure by default and "unbreakable" thanks to bootable Btrfs snapshots. People who still depend on Microsoft software can optionally run Windows apps seamlessly in a VM.

> *Beautiful as glass. Strong as a fortress.*

This file tells you (Claude Code) **how to work** in this repository. **What to build** is specified in `docs/`. Read this file completely at the start of every session, then read the docs relevant to your task.

---

## 1. Session start (always, in this order)

1. Read `PROGRESS.md`.
2. If "Current task" has status `in progress` or `blocked`, an earlier session was interrupted (crash, power or internet loss). Reconstruct the state before doing anything else:
   - `git status` and `git diff` (uncommitted work)
   - `git log --oneline -10`
   - `git log origin/main..HEAD --oneline` (unpushed commits)
   - `git stash list`

   Continue from "Next step if interrupted". Do **not** start the task over and do not discard uncommitted work without asking.
3. If there are unpushed commits, push them first: `git push origin main`. On success, clear "Unpushed commits" in `PROGRESS.md`.
4. Run `git pull --rebase origin main` before starting new work.
5. Tell the maintainer in German, in 2–3 lines, what state you found and what you will do next.

---

## 2. Workflow for every change (mandatory)

The order matters: **the progress note is written before any other file is touched.** If the session, the power or the internet drops, `PROGRESS.md` on disk shows exactly where work stopped.

1. **Note first.** Update `PROGRESS.md` → "Current task":
   - Status: `in progress`
   - Task, start time (ISO 8601), related roadmap item
   - Plan as a checklist (`- [ ]`)
   - Files you expect to touch
   - "Next step if interrupted": one concrete sentence

   Save the file **before** editing anything else.
2. **Work in small steps.** After each step, tick it in `PROGRESS.md` and update "Next step if interrupted".
3. **Check.** Run the checks for the area you changed (§5). Never commit failing code.
4. **Commit.** One commit per change or feature (§3). Include the `PROGRESS.md` update in the same commit: add a line to "Log" (newest first) and set "Current task" back to `idle`.
5. **Push immediately:** `git push origin main`.
   - If the push fails (offline, authentication): keep the commit local, write its hash under "Unpushed commits" in `PROGRESS.md` (leave this edit uncommitted), tell the maintainer and stop. The next session pushes first (§1, step 3).
6. **Large features** are split into several commits. Each commit leaves the repository in a working state, and each is committed and pushed on its own. The full plan stays in `PROGRESS.md` until the feature is complete.

If you are blocked (missing information, failing tool, decision needed), set status `blocked`, write the reason into `PROGRESS.md`, and ask the maintainer.

---

## 3. Commit rules

- Format: [Conventional Commits](https://www.conventionalcommits.org/) – `type(scope): summary`
  - Types: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, `perf`, `style`
  - Scopes = components: `settings`, `theme`, `shell`, `timemachine`, `update`, `assistant`, `helper`, `windows`, `installer`, `firstboot`, `iso`, `repo`, `ci`, `docs`, `website`, `progress`
- Summary: English, imperative mood, at most 72 characters.
- Body (required for everything except trivial docs fixes):
  - what changed and **why**
  - how it was tested (or which checks could not run, and why)
  - related roadmap item, e.g. `Roadmap: Phase 2 – Time Machine`
- One logical change per commit. Never mix refactoring with features.
- **Never:** `git push --force`, rewriting pushed history, `--no-verify`, committing secrets (GPG private keys, tokens, API keys, Windows product keys), committing build artifacts (ISOs, `*.pkg.tar.zst`, VM images).

Example:

```
feat(timemachine): list snapper snapshots in system settings

Add a System Settings module that reads snapshots through snapper's
D-Bus service and shows them as a timeline (date, description,
pre/post pair). Read-only for now; restore follows in a separate commit.

Tested: qmllint, manual test in a QEMU VM with 12 snapshots.
Roadmap: Phase 2 – Time Machine
```

---

## 4. Language and communication

- Everything in the repository is **English**: code, comments, docs, commit messages, UI strings.
- Talk to the maintainer (Jan) in **German**, short and direct.
- All UI strings are translatable from day one (KDE `ki18n` for C++/QML, gettext for Python).

---

## 5. Checks before every commit

| Area | Checks |
|---|---|
| Shell scripts | `shellcheck` |
| PKGBUILDs | `namcap`; build in a clean chroot (`extra-x86_64-build` or `makechrootpkg`) when available |
| Rust (helper) | `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` |
| Python (assistant) | `ruff check`, `ruff format --check`, `pytest` |
| QML | `qmllint` |
| Settings registry (TOML) | `scripts/validate-registry` against the schema |
| Docs | relative links resolve; content consistent with `docs/DECISIONS.md` |

If a tool is not available in your environment, write `Not run: <check> (<reason>)` into the commit body. Never skip silently.

---

## 6. Hard rules (never break these)

1. Decisions marked **Decided** in `docs/DECISIONS.md` are fixed. Do not change them without asking. If implementation reveals a problem, stop and ask.
2. Ask before you: add a runtime dependency to a core package, change the security model (`docs/02-system.md`, `docs/05-assistant.md`), change branding (`docs/03-desktop-design.md`), or change the release model.
3. Never run destructive disk operations on the host (partitioning, `mkfs`, bootloader installation, `snapper rollback`, `sbctl enroll-keys`). Test in QEMU VMs only.
4. Never use `pacman -Sy` without `-u` in any script or code path (partial upgrades break Arch systems).
5. Never sign kernels or initramfs with sbctl. Limine verifies them through BLAKE2B hashes in `limine.conf`; signing breaks this.
6. Never add AUR dependencies to packages in the `[glassfort]` repository. If something is only in the AUR, package it ourselves in `components/` after review.
7. Never commit signing keys. The repository signing key stays offline with the maintainer.
8. The AI assistant never gets a free shell or root. It may only call typed tools that the privileged helper validates (`docs/05-assistant.md`).
9. Never ship, download or link modified Windows images (Tiny10/Tiny11 etc.), Windows product keys or activation tools.
10. Never use Arch Linux's name or logo as part of Glassfort's branding, and never use Apple or Microsoft assets (icons, fonts such as SF Pro, wallpapers).

---

## 7. Where to find what

| File | Content |
|---|---|
| `PROGRESS.md` | Current task, unpushed commits, work log |
| `docs/00-overview.md` | Vision, positioning, principles, glossary |
| `docs/01-architecture.md` | Stack, repository layout, packages, release model, kernels, build pipeline |
| `docs/02-system.md` | Filesystem, snapshots, boot, Secure Boot, encryption, hardening, drivers, updates |
| `docs/03-desktop-design.md` | Plasma curation, UX, shortcuts, default apps, CI and branding |
| `docs/04-installer.md` | Installer and first-boot experience |
| `docs/05-assistant.md` | AI assistant: architecture, tools, security model |
| `docs/06-windows-apps.md` | Optional Windows apps module |
| `docs/07-testing.md` | Test hardware, VM tests, CI |
| `docs/08-release-legal.md` | Licensing, trademarks, hosting, community, legal |
| `docs/09-roadmap.md` | Phases, deliverables, done criteria |
| `docs/DECISIONS.md` | All decisions with status (Decided / Proposed / Open) |

When you change architecture or behaviour, update the matching doc **in the same commit**. New decisions go into `docs/DECISIONS.md` as `Proposed` until the maintainer confirms them.

---

## 8. Environment notes

- Building packages and the ISO requires Arch Linux (`pacman`, `makepkg`, `devtools`, `archiso`). If you are not on Arch, use an `archlinux:latest` container or CI.
- VM testing: QEMU/KVM with OVMF (UEFI) and `swtpm` (TPM 2.0). Secure Boot tests use OVMF with enrolled custom keys.
- The git remote is `origin`, the default branch is `main`.
