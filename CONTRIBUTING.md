# Contributing to Glassfort

Thanks for your interest in Glassfort! The project is in early planning, so
the most useful contributions right now are feedback on the specification in
[`docs/`](docs/) and small, focused pull requests.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
Security problems are reported privately – see [`SECURITY.md`](SECURITY.md).

## Where to go

- **Using Glassfort:** the [user guide](https://github.com/glassfortos/GlassfortOS/wiki)
  in the wiki. It only describes what is built and tested; the
  specification is in [`docs/`](docs/) (D-47). If your change alters what a
  wiki page says, update the page too.
- **Questions and help:** [Discussions → Q&A](https://github.com/glassfortos/GlassfortOS/discussions/categories/q-a).
  Glassfort is based on Arch Linux but is not supported by the Arch
  community, so please do not ask the Arch forums about it.
- **Ideas and feedback:** [Discussions → Ideas](https://github.com/glassfortos/GlassfortOS/discussions/categories/ideas).
- **Bugs and concrete feature requests:** [Issues](https://github.com/glassfortos/GlassfortOS/issues/new/choose),
  using the bug report or feature request form. New issues get the
  `triage` label; maintainers add an `area: …` label.

## Before you start

- Read [`docs/00-overview.md`](docs/00-overview.md) and the doc for the area
  you want to work on.
- Decisions marked **Decided** in [`docs/DECISIONS.md`](docs/DECISIONS.md)
  are fixed. If you think one is wrong, open an issue first instead of a pull
  request.
- For anything larger than a bug fix, open an issue to discuss the approach.

## Repository layout

One folder per package under `components/`, each with its source, a
`PKGBUILD`, a short `README.md` and its tests. See
[`docs/01-architecture.md`](docs/01-architecture.md) for the full layout.

## Rules

- Everything in the repository is **English**: code, comments, docs, commit
  messages and UI strings. All UI strings must be translatable (KDE `ki18n`
  for C++/QML, gettext for Python).
- Every source file starts with an SPDX header, for example
  `# SPDX-License-Identifier: GPL-3.0-or-later`.
- Never use `pacman -Sy` without `-u`: partial upgrades break Arch systems.
- No AUR dependencies in `[glassfort]` packages. If something is only in the
  AUR, it is reviewed and packaged in `components/third-party/`.
- Never commit secrets (keys, tokens, product keys) or build artifacts (ISOs,
  `*.pkg.tar.zst`, VM images).
- Never use Arch Linux, Apple or Microsoft names, logos or assets in
  Glassfort branding.

## Commits

We use [Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): summary`.

- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`,
  `perf`, `style`
- Scopes are components: `settings`, `theme`, `shell`, `timemachine`,
  `update`, `assistant`, `helper`, `windows`, `installer`, `firstboot`,
  `iso`, `repo`, `ci`, `docs`
- Summary in imperative mood, at most 72 characters.
- The body explains what changed and why, and how you tested it.
- One logical change per commit. Do not mix refactoring with features.

## Checks

Run the checks for the area you changed before you open a pull request:

| Area | Checks |
|---|---|
| Shell scripts | `shellcheck` |
| PKGBUILDs | `namcap`, build in a clean chroot (`extra-x86_64-build`) |
| Rust | `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` |
| Python | `ruff check`, `ruff format --check`, `pytest` |
| QML | `qmllint` |
| Docs | relative links resolve (`scripts/check-links`) |

CI runs the same checks on every pull request.

## Testing system changes

Never test partitioning, bootloader or Secure Boot changes on your own
machine. Use a QEMU/KVM VM with OVMF (UEFI) and `swtpm` (TPM 2.0), as
described in [`docs/07-testing.md`](docs/07-testing.md).

## Licensing

By contributing you agree that your code is licensed under
GPL-3.0-or-later and your documentation and artwork under CC BY-SA 4.0
(see [`LICENSE`](LICENSE) and [`LICENSES/`](LICENSES/)). Contributions do
not grant any rights to the Glassfort name or logo
(see [`TRADEMARKS.md`](TRADEMARKS.md)).
