# Website

The Glassfort website: one static page, no build step, published to GitHub
Pages by [`.github/workflows/pages.yml`](../.github/workflows/pages.yml) on
every push to `main` that touches this folder (decision D-43 in
[`docs/DECISIONS.md`](../docs/DECISIONS.md)).

| File | Content |
|---|---|
| `index.html` | The page |
| `style.css` | Palette and type from [`docs/03-desktop-design.md`](../docs/03-desktop-design.md) |
| `main.js` | Logo tilt, the rollback demo, light/dark switch, download box |
| `release.json` | The published ISO (see below) |
| `fonts/` | Inter (variable, SIL Open Font License, `LICENSE-Inter.txt`) |
| `img/` | Logo (copied from `components/glassfort-branding`) and screenshots from the VM tests |

Rules: no trackers, no cookies, nothing loaded from other servers (fonts are
self-hosted; embedding Google Fonts is a GDPR problem in Germany). Features
that do not exist yet are marked as planned. No Arch, Apple or Microsoft
logos or names in the branding (`CLAUDE.md` §6.10); "Based on Arch Linux"
in the footer is allowed (docs/08).

## Publishing an ISO

The download box shows "no public ISO yet" until `release.json` has a URL.
To publish a release, fill in all fields and push:

```json
{
  "version": "2027.01",
  "date": "2027-01-15",
  "url": "https://…/glassfort-2027.01-x86_64.iso",
  "size": "2.6 GB",
  "sha256": "…",
  "signature": "https://…/glassfort-2027.01-x86_64.iso.sig"
}
```

The ISO itself is not hosted here: GitHub limits release files to 2 GiB
(docs/08, Hosting). `signature` may be `null` until the signing key exists
(D-26).

## Local preview

```sh
python3 -m http.server -d website 8000   # then open http://127.0.0.1:8000
```

`release.json` is fetched, so opening `index.html` as a file shows the
page without the download details.
