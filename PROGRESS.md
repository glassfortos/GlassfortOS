# Progress

This file is the single source of truth for "what is happening right now".
Claude Code updates it **before** changing any other file (see `CLAUDE.md` §2).

## Current task

- **Status:** in progress  <!-- idle | in progress | blocked -->
- **Task:** Phase 0 – repository foundation
- **Roadmap item:** Phase 0
- **Started:** 2026-11-22T22:10:00+01:00
- **Plan:**
  - [x] Commit 1: LICENSE, LICENSES/CC-BY-SA-4.0.txt, TRADEMARKS.md
  - [x] Commit 2: CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md
  - [x] Commit 3: repository layout skeleton, .gitignore, scripts/check-links
  - [x] Commit 4: empty glassfort-settings package (PKGBUILD + README)
  - [x] Commit 5: CI skeleton (shellcheck, link check, namcap, clean-chroot build)
  - [ ] Verify CI run is green on GitHub
- **Files expected to change:** LICENSE, LICENSES/, TRADEMARKS.md, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md, .gitignore, components/, iso/, repo/, scripts/, tests/, .github/workflows/, README.md, PROGRESS.md
- **Next step if interrupted:** Check the CI run on GitHub (gh run list) and fix failures
- **Blocked because:** –

## Unpushed commits

<!-- Hash + summary of commits that could not be pushed. Cleared after a successful push. -->
- none

## Log (newest first)

| Date | Commit | Summary |
|---|---|---|
| 2026-11-22 | – | Add CI skeleton with lint and clean-chroot package build |
| 2026-11-22 | – | Add empty glassfort-settings package |
| 2026-11-22 | – | Add repository layout skeleton and link checker |
| 2026-11-22 | – | Add contributing guide, security policy and code of conduct |
| 2026-11-22 | – | Add licences and trademark policy |
| 2026-11-22 | – | Imported project specification into repository root |
| 2026-11-22 | – | Project specification created (`CLAUDE.md`, `PROGRESS.md`, `docs/`) |
