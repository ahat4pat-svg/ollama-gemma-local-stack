# Install Hermes Agent on Windows (HP Pavilion, 16 GB)

Step-by-step PowerShell guide. Use this alongside `install.ps1` — the script
automates the same steps, this doc explains the *why* and lists fallbacks.

> **Validated on Linux container** : the entire install + skills + dashboard +
> kanban flow was verified end-to-end in a Linux container before this doc was
> written. The PowerShell equivalent on Windows uses the same official Nous
> installer, just with `.ps1` instead of `.sh`.

## TL;DR

```powershell
.\setup\hermes\install.ps1
```

After install, three commands give you the whole stack :

```powershell
hermes              # interactive chat
hermes dashboard    # web UI on http://127.0.0.1:9119  ← this IS Mission Control
hermes gateway run  # task dispatcher for Kanban (optional)
```

## What you're installing

| Component | Source | Role |
|---|---|---|
| **Hermes Agent** | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | Self-improving AI agent, runs locally, calls Gemma via Ollama |
| **85 bundled skills** | shipped with Hermes | Capabilities (github, devops, research, software-development, etc.). Installed automatically. |
| **Web dashboard** | built-in (`hermes dashboard`) | Manages config, sessions, API keys, embedded chat (with `--tui`). **This is what people mean by "Mission Control" for Hermes.** |
| **Kanban board** | built-in (`hermes kanban`) | Durable SQLite task board with dispatcher, swarms, parent/child deps |
| **Messaging gateway** | built-in (`hermes gateway`) | Telegram / Discord / WhatsApp / Slack bridges + Kanban dispatcher |

Version validated : Hermes Agent **v0.14.0 (2026.5.16)**.

## Why we don't use builderz-labs/mission-control

There's a popular community project called
[`builderz-labs/mission-control`](https://github.com/builderz-labs/mission-control)
that markets itself as a dashboard for AI agents. It works, but :

- Hermes ships its OWN web dashboard (`hermes dashboard`). It speaks Hermes' config
  format natively — no adapter glue.
- builderz-labs/MC adds Node.js dev server (~800 MB RAM), SQLite, a separate port.
  On a 16 GB box already running Ollama + Gemma + Hermes, that's wasteful.
- The builderz-labs UI uses CrewAI / LangGraph / AutoGen adapters. Hermes works,
  but it's the long way around.

**Use the built-in `hermes dashboard`**. If you ever outgrow it (multiple
agents from different frameworks), revisit builderz-labs/MC then.

## 1. Prereqs

Ollama + Gemma 4 must already run on this HP. From PowerShell :

```powershell
Invoke-RestMethod http://localhost:11434/api/tags
ollama list
```

If either fails, finish `../windows/install.ps1` first.

## 2. RAM budget reality check (16 GB)

| Process | RAM |
|---|---|
| Windows + background | ~ 3-4 GB |
| Ollama runtime (idle) | ~ 0.2 GB |
| Gemma 4 E4B loaded | ~ 4-5 GB |
| Hermes Agent (Python) | ~ 0.3-0.6 GB |
| Hermes dashboard (Node, when launched) | ~ 0.3-0.5 GB |
| Hermes gateway (Python, optional) | ~ 0.2 GB |
| **Total when everything active** | **~ 8-10 GB** |

Tight but fine. Headroom is for Gemma's KV cache to grow during long chats.

## 3. Install Hermes Agent

Nous Research's official PowerShell one-liner :

```powershell
iex (irm https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1)
```

This pulls **Python 3.11, Node 22, ripgrep, ffmpeg, git** as dependencies,
then installs Hermes Agent and syncs **85 bundled skills** into
`~/.hermes/skills/`.

**Relaunch PowerShell** so `hermes` lands in PATH, then verify :

```powershell
hermes --version
# Hermes Agent v0.14.0 (2026.5.16)
```

## 4. About skills — what was wrong in my first draft

Earlier drafts of this doc said there was no "install all skills" command.
**That was wrong.** Reality :

- The installer above **automatically syncs 85 bundled skills** into
  `~/.hermes/skills/`. You don't need to do anything extra.
- They're organized in 24 categories : `apple`, `autonomous-ai-agents`,
  `creative`, `data-science`, `devops`, `diagramming`, `domain`, `email`,
  `gaming`, `gifs`, `github`, `inference-sh`, `mcp`, `media`, `mlops`,
  `note-taking`, `productivity`, `red-teaming`, `research`, `smart-home`,
  `social-media`, `software-development`, `yuanbao`, `dogfood`.
- Confirm with : `hermes skills list`

Hermes also has a full skill management subcommand if you want to install
community skills later :

```powershell
hermes skills browse                # paginated browser
hermes skills search <keyword>      # search registries
hermes skills install <name>        # install one
hermes skills uninstall <name>      # remove
hermes skills config                # enable/disable individual skills
```

And Hermes **creates new skills autonomously** as procedural memory after
complex tasks — they appear under `~/.hermes/skills/` over time.

## 5. Configure Hermes to use local Ollama

```powershell
hermes setup model
```

Wizard prompts :

| Field | Value |
|---|---|
| Provider | `ollama` (this is an alias for "custom" in the config) |
| Base URL | `http://localhost:11434` |
| Default model | `gemma4:e4b` (or whatever `ollama list` shows) |

Behind the scenes this edits `~/.hermes/config.yaml` :

```yaml
model:
  default: "gemma4:e4b"
  provider: "ollama"      # alias maps to "custom"
  base_url: "http://localhost:11434"
```

You can also add cloud providers later (`hermes setup model` again, or edit
`config.yaml`). If you run LiteLLM (see `../litellm/`), point Hermes at
LiteLLM (`http://localhost:4000`) instead of directly at Ollama for routing
+ cloud fallback.

## 6. Initialize the Kanban task board

```powershell
hermes kanban init
# Creates ~/.hermes/kanban.db (SQLite, durable across reboots)
```

You can now create tasks from CLI :

```powershell
hermes kanban create -t "Draft cold-email for prospect X" -b default
hermes kanban list
hermes kanban show <task-id>
```

Tasks don't execute until the gateway runs (next step).

## 7. Launch the stack

Three PowerShell windows :

```powershell
# Window 1 — interactive chat
hermes
```

```powershell
# Window 2 — built-in web dashboard (the "Mission Control")
hermes dashboard
# Opens browser to http://127.0.0.1:9119
# Add --tui to embed Hermes chat directly in the browser :
#   hermes dashboard --tui
```

```powershell
# Window 3 (optional) — Kanban dispatcher
hermes gateway run
# Foreground mode. Picks up ready tasks from the Kanban board.
# Ctrl-C to stop. To install as a Windows service instead :
#   hermes gateway install   (may require admin)
```

## 8. Smoke test

In Hermes chat (window 1) :

```
Say hi in one sentence.
```

Watch `ollama ps` in another window — you should see `gemma4:e4b` loaded.
Confirms the wiring works end-to-end.

## Troubleshooting

| Issue | Fix |
|---|---|
| `hermes` not found after install | Relaunch PowerShell. PATH only updates for new sessions. |
| `hermes setup model` can't reach Ollama | `Invoke-RestMethod http://localhost:11434/api/tags` — if it hangs, Ollama isn't running or `OLLAMA_HOST` is off |
| Gemma OOMs after adding Hermes | Stop `hermes dashboard` and `hermes gateway run` first to free RAM. Long-term : queue requests through LiteLLM with concurrency 1 |
| `hermes dashboard` says port 9119 busy | `hermes dashboard --port 9120` |
| `hermes dashboard --status` shows phantom processes | Known false-positive in PID search — `hermes dashboard --stop` will still work to clean up real instances |
| `hermes doctor` flags missing deps | Run `hermes postinstall` to re-bootstrap node/ripgrep/ffmpeg |
| First chat is slow | Gemma loads on demand. Check `OLLAMA_KEEP_ALIVE` env var on Windows (see `../windows/`) |
| Kanban task stays in "ready" forever | `hermes gateway run` isn't running. Start it in a separate window |

Useful diagnostics :

```powershell
hermes status        # all components health
hermes doctor        # detailed config + dep check
hermes dump          # full setup summary (paste in TROUBLESHOOTING.md when stuck)
```

## What to do next

Once Hermes + dashboard + Kanban are running :

1. Wire Hermes' OpenAI-compatible proxy (`hermes proxy`) as a LiteLLM backend
   so other apps in your stack can route through Hermes.
2. Set up the messaging gateway for the platforms you actually use :
   `hermes setup gateway` → pick Telegram / Slack / Discord / WhatsApp.
3. Benchmark same task through Hermes-on-Gemma vs Hermes-on-cloud. Log
   numbers in `../../benchmarks/`.
4. Log any HP-specific gotcha (firewall, scheduled tasks, sleep mode) in
   `../../docs/TROUBLESHOOTING.md`.
