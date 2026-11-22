# 05 – AI assistant

Users chat with the system in plain language: *"Install Discord"*, *"Update my system"*, *"Turn on dark mode"*. The system does it.

**Core principle: the AI plans, the system executes.** The model never gets a shell or root. Security must not depend on the model behaving correctly: treat the model like an untrusted user making suggestions. Rules in a system prompt are **not** a security control.

## Architecture

```
Chat Plasmoid (user, no privileges)
        │  D-Bus: org.glassfort.Assistant
        ▼
Assistant service (user, sandboxed, Python) ◄──► Model (local Ollama/llama.cpp or cloud provider)
        │  D-Bus: org.glassfort.Helper  (typed tool calls only)
        ▼
Helper (root, Rust, no AI) ── polkit dialog for red actions ──► user enters password
        │  validated actions only
        ▼
System: pacman, Flatpak, KConfig, snapper, firewalld, NetworkManager, systemd
```

| Process | Runs as | Responsibilities |
|---|---|---|
| Chat Plasmoid | user | Chat UI, action cards (Install / Cancel / Undo), progress |
| Assistant service | user, sandboxed | Talks to the model, turns messages into typed tool calls, MCP server |
| Helper | root | Schema validation, allowlists, dry run, snapshot, execution, audit log; builds the confirmation text itself |

## Providers

- Configured once in System Settings → Assistant: **Off** (default), **Local** (Ollama/llama.cpp), **OpenAI-compatible endpoint**, **Anthropic**, **Google Gemini**.
- Other apps never need their own API keys; they ask the assistant service via D-Bus.
- Small local models are often unreliable at tool calling; the permission levels protect in every case.
- Cloud mode shows what is sent.

## Entry points

- Chat Plasmoid sliding in from the right: Copilot key, `Super+A`, Start menu search ("Ask Glassfort …")
- Dolphin context menu: *Summarise*, *Rename sensibly*
- Selected text and screenshots: *Ask about this*

## Tools and permission levels

| Level | Behaviour | Tool groups (examples) |
|---|---|---|
| **Green** | Runs immediately | `disk_usage`, `read_journal(unit, since)`, `network_status`, `list_snapshots`, `list_updates`, `search_packages(query)` |
| **Yellow** | Runs immediately, Undo button | `set_setting(id, value)` for user settings, `flatpak_install(app_id)` / `flatpak_remove` (user scope) |
| **Red** | Confirmation + password (polkit) | `install_packages(names[])`, `remove_packages(names[])`, `system_update()`, `service_enable(unit)`, `firewall_open_port(port, zone)`, `restore_snapshot(id)` |
| **Locked** | Not available to the assistant | Partitioning, bootloader, deleting snapshots, Secure Boot, disabling the firewall or AppArmor |

Package rules: official repositories and `[glassfort]` (signed) plus **verified** Flathub apps only. AUR and `curl | bash` are never available to the assistant.

## Settings registry

The assistant can only change settings listed in the registry. Files live in `/usr/share/glassfort/settings.d/*.toml`, are **root-owned and only changed by packages** (a user-writable registry would let malware unlock settings), and are validated against a schema at load time.

Backends:

- `kconfig` – read/write KConfig keys, then reload via D-Bus
- `dbus` – call a fixed method with typed arguments
- `exec` – run a fixed binary; arguments only from validated values; **never a shell**

```toml
[[setting]]
id        = "appearance.color_scheme"
title     = "Light or dark mode"
type      = "enum"
values    = ["light", "dark"]
level     = "yellow"   # green | yellow | red
read      = { backend = "kconfig", file = "kdeglobals", group = "General", key = "ColorScheme" }
write     = { backend = "exec", program = "/usr/bin/plasma-apply-colorscheme", args = ["{value}"] }
mapping   = { light = "GlassfortLight", dark = "GlassfortDark" }
```

Undo: the helper reads the old value before writing and stores it in the history. Start with about 20 common settings and grow from there.

## Security model

| Risk | Countermeasure |
|---|---|
| Model makes mistakes | Dry run (`pacman -S --print`, `pacman -R --print`) shows the real transaction; snapshot before every red action |
| Prompt injection (package descriptions, web pages, files, logs) | Tool output is data, never instructions. Once untrusted content is in the context, every following change needs confirmation. Untrusted content is processed by a separate model call **without tools** that only returns structured data (dual-LLM pattern). |
| Model confirms its own action | No input simulation, no screen control for the assistant. Confirmation only through the polkit agent dialog. |
| Malware abuses the service for root | polkit actions use `auth_admin` (password/fingerprint every time), never `auth_admin_keep` |
| Dangerous packages | Signed repo packages and verified Flathub apps only |
| System gets dismantled | Helper refuses transactions that remove protected packages (`base`, `linux`, `linux-lts`, `plasma-desktop`, all `glassfort-*`) |
| Private data sent to the cloud | Sandbox makes `~/.ssh`, browser profiles, KWallet and password manager data invisible to the service |
| Loops and mass actions | Maximum number of actions per request |

### Implementation rules

- No free shell. Only defined tools with strict schemas and allowlists.
- The confirmation dialog text is generated by the **helper** from validated parameters – never by the model.
- No partial upgrades (never `pacman -Sy` without `-u`).
- The helper stays small, written in Rust, and gets an external review before 1.0.
- Assistant service sandbox (systemd user unit and/or bubblewrap): `NoNewPrivileges=yes`, no access to private directories, network only to the configured provider.
- Confirmations are rare but meaningful: only red actions ask for a password; risks are highlighted ("removes 3 packages", "opens port 22").

### Accountability

- **Assistant history** in System Settings: every action with time, request, result and Undo.
- Kill switch: one toggle disables the helper's assistant interface entirely.
- CI runs a prompt-injection test suite; the helper's D-Bus interface is fuzzed; `SECURITY.md` explains how to report vulnerabilities.

### Residual risks (document them for users)

- The user confirms something harmful.
- In cloud mode the provider sees what the assistant may read.
- Bugs in the helper.
- Snapshots do not undo data leaks.

## MCP server

The same tools are exposed as an MCP server so other AI clients (Claude Desktop, Codex, local agents) can operate Glassfort with the **same permission levels** – every call still goes through the helper.

## Defaults

- Off by default; `glassfort-assistant` is an optional package, chosen at first boot.
- Local first: privacy-friendly local mode is offered before cloud providers.

## MVP (Roadmap Phase 3)

1. Search and install packages (repo + Flatpak)
2. System update with snapshot
3. 10 common settings via the registry
4. Chat Plasmoid with action cards

Build the helper and MCP server first – they work immediately with existing AI clients – then the chat Plasmoid.
