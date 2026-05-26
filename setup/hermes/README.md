# Hermes Agent setup (HP, with native dashboard + kanban)

Install [Hermes Agent](https://github.com/NousResearch/hermes-agent)
(Nous Research's self-improving AI agent, v0.14.0+) on the HP, wired to
your local Ollama+Gemma via loopback. Uses Hermes' **built-in web dashboard**
(`hermes dashboard`, port 9119) and **built-in Kanban task board**
(`hermes kanban`) — no extra software needed.

- **One-shot script** : [`install.ps1`](install.ps1)
- **Manual guide** : [`install-hermes-windows.md`](install-hermes-windows.md)

## Quick start

From PowerShell on the HP (NOT as Administrator) :

```powershell
.\setup\hermes\install.ps1
```

After install, three commands cover the whole stack :

```powershell
hermes              # interactive chat
hermes dashboard    # web UI on http://127.0.0.1:9119  ← Mission Control
hermes gateway run  # task dispatcher for Kanban (optional)
```

## What's bundled (validated 2026-05-26)

- **85 skills** install automatically with `install.ps1`. Run
  `hermes skills list` to see them all.
- **Web dashboard** at `http://127.0.0.1:9119` — config, sessions, API keys,
  embedded chat (`--tui` flag).
- **Kanban board** stored in `~/.hermes/kanban.db` (SQLite, durable).
- **Messaging gateway** ready for Telegram / Discord / Slack / WhatsApp etc.
  (run `hermes setup gateway` to configure).
- **Config** in `~/.hermes/config.yaml` (YAML, not TOML).

## What we deliberately don't install

[`builderz-labs/mission-control`](https://github.com/builderz-labs/mission-control)
is a popular community dashboard for AI agents, but it duplicates what
`hermes dashboard` already does natively — and adds a Next.js dev server
that costs ~800 MB RAM on a 16 GB box. Skip it unless you're orchestrating
multiple non-Hermes agents too.
