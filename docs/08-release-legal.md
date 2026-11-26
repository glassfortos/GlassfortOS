# 08 – Release, licensing, legal, community

## Licensing (Decided)

| What | Licence |
|---|---|
| Source code | **GPL-3.0-or-later** (fits the KDE ecosystem) |
| Documentation, wallpapers, other artwork | **CC BY-SA 4.0** |
| Name "Glassfort" and the Glassfort logo | **Excluded** from both licences; governed by `TRADEMARKS.md` (like Arch and Fedora) |

Every source file carries an SPDX header, e.g. `# SPDX-License-Identifier: GPL-3.0-or-later`. Third-party packages in `components/third-party/` keep their upstream licences.

## Trademarks

- Glassfort's own trademark policy (`TRADEMARKS.md`): allowed uses (news, reviews, unmodified redistribution), forbidden uses (modified builds under the Glassfort name, implying endorsement).
- Arch Linux: never use the Arch name or logo in our branding. "Based on Arch Linux" in descriptions is fine. In doubt: trademarks@archlinux.org.
- Arch-based distributions are not supported by the Arch community → Glassfort runs its own support channel.
- Never use Apple or Microsoft assets or marks in branding.
- Before launch: check trademark registers (USPTO, EUIPO, DPMA; classes 9 and 42).

## Domains and handles

- Planned: `glassfort.org` (primary), `glassfortos.com` (redirect). `glassfort.com` is taken.
- GitHub organisation: `glassfortos` (secured 2026-11-25; `glassfort` belongs to an unrelated user account).
- Secure: Flathub app IDs, social media handles.

## Hosting

- Code, issues, CI: GitHub
- Website: static page in `website/`, GitHub Pages until `glassfort.org` exists (D-43, Proposed). No trackers, no cookies, no third-party requests. The ISO download link comes from `website/release.json`.
- ISO: SourceForge and/or own mirror (GitHub Releases has a 2 GiB per-file limit)
- `[glassfort]` repository: primary server + mirrors

## Versioning *(Proposed)*

- ISO releases dated `YYYY.MM` like Arch (e.g. `2027.03`), optional codenames for marketing.
- Packages follow their own semantic versions.

## Signing key (Decided)

- The repository signing key is the most valuable asset of the project: keep it offline (hardware token such as a YubiKey), plus an offline backup and a revocation certificate.
- CI builds unsigned packages; the maintainer signs and publishes.
- Until the real key exists, VM tests use a throwaway key generated inside the VM; it is never committed or published.

## Telemetry and privacy *(Proposed)*

- No telemetry, or strictly opt-in.
- Privacy policy covering the assistant's cloud mode and the website.

## Community *(Open)*

- Support channel: forum, Matrix or Discord
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` (vulnerability reporting)

## Legal, Germany *(Open – not legal advice)*

- Website: imprint (Impressum, usually required under § 5 DDG) and privacy policy (GDPR).
- If the maintainer's employment contract regulates side activities, check whether the project needs to be reported, especially once donations or income are involved.
