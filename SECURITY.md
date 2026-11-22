# Security policy

Glassfort promises to be secure by default. If you find a weakness, please
tell us privately first so we can fix it before it is public.

## Supported versions

Glassfort is in early planning; there is no release yet. Once releases
exist, only the current ISO release and the latest packages in the
`[glassfort]` repository receive security fixes (Glassfort is a rolling
release).

## Reporting a vulnerability

- **Do not open a public issue** for security problems.
- Use GitHub's private reporting: in this repository, go to
  **Security → Report a vulnerability**.
- Include what you found, the affected component (for example
  `glassfort-helper` or `glassfort-assistant`), steps to reproduce, and the
  impact you expect.

We aim to confirm your report within 7 days and to agree on a disclosure
date with you. We credit reporters in the release notes unless you prefer
to stay anonymous.

## Scope

In scope: everything in this repository – Glassfort packages, the
`[glassfort]` repository and its signing, the ISO, the installer, the
privileged helper (`glassfort-helper`) and the AI assistant
(`glassfort-assistant`), including prompt injection that leads the assistant
to perform actions the user did not confirm.

Out of scope: vulnerabilities in upstream software that Glassfort uses
unchanged (Arch Linux packages, KDE Plasma, the Linux kernel, Windows).
Please report those to the upstream project. If Glassfort's configuration
makes an upstream issue worse, that is in scope.

## Signing keys

Glassfort packages and ISOs are signed. Only trust keys shipped in the
`glassfort-keyring` package. If you suspect a signing key is compromised,
report it immediately through the private channel above.
