# Install Hermes Agent + Mission Control on Windows (HP Pavilion, 16 GB)

Step-by-step PowerShell guide. Use this alongside `install.ps1` — the script
automates the same steps, this doc explains the *why* and lists fallbacks.

> **Where it runs** : everything on the HP itself. Hermes calls Ollama via
> loopback (`http://localhost:11434`), Mission Control serves on
> `http://localhost:3000`. No Tailscale hop needed in the agent → model loop.

## 0. What you're installing

| Component | Repo | Role |
|---|---|---|
| **Hermes Agent** | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | Self-improving AI agent, runs locally, calls Gemma via Ollama |
| **Mission Control** | [builderz-labs/mission-control](https://github.com/builderz-labs/mission-control) | Web dashboard to monitor + dispatch tasks to Hermes |
| **Skills** | bundled + [agentskills.io](https://agentskills.io) | Capabilities ; bundled ones ship with Hermes, more importable on demand |

Versions tested : Hermes Agent v0.14.0 (2026.5.16), Mission Control (May 20, 2026 build).

## 1. Prereqs (verify before installing)

Ollama + Gemma 4 must already be running on this HP. From PowerShell :

```powershell
# Ollama API responding?
Invoke-RestMethod http://localhost:11434/api/tags

# Models pulled?
ollama list
```

If either fails, finish `../windows/install.ps1` first.

## 2. RAM budget reality check (16 GB)

Rough live footprint when everything is loaded :

| Process | RAM |
|---|---|
| Windows + background | ~ 3-4 GB |
| Ollama runtime (idle) | ~ 0.2 GB |
| Gemma 4 E4B loaded | ~ 4-5 GB |
| Hermes Agent | ~ 0.2-0.5 GB |
| Mission Control (Next.js dev) | ~ 0.4-0.8 GB |
| **Total when chatting** | **~ 8-10 GB** |

Tight but workable. If Gemma OOMs after you add Hermes + Mission Control,
suspect those two first. Options :
- Switch Mission Control to Docker prod build (`docker compose up`) instead of `pnpm dev` — lower RAM.
- Run Mission Control on the Toshiba "Mister-B" instead, point it at Hermes on HP over Tailscale.

## 3. Install Hermes Agent

Nous Research's official PowerShell installer (pulls Python 3.11, Node, ripgrep, ffmpeg, git, then Hermes itself) :

```powershell
iex (irm https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1)
```

**Relaunch PowerShell** so `hermes` lands in PATH, then verify :

```powershell
hermes --version
```

## 4. Configure Hermes to use local Ollama

```powershell
hermes setup
```

When the wizard asks about model providers :

| Field | Value |
|---|---|
| Provider type | `ollama` |
| Base URL | `http://localhost:11434` |
| Default model | `gemma4:e4b` (or whatever you pulled — check `ollama list`) |

You can also add cloud providers (OpenRouter, Anthropic, OpenAI) here — Hermes
will route across them. If you run LiteLLM (see `../litellm/`), point Hermes
at LiteLLM (`http://localhost:4000` or wherever) instead of directly at Ollama
for routing + fallback.

## 5. Initialize skills directory + smoke test

```powershell
hermes
```

This opens interactive chat AND creates `~/.hermes/` (including `skills/`)
on first run. Type a short prompt to confirm it roundtrips through Gemma.
Then `Ctrl-C` to exit.

Browse what's there :

```powershell
Get-ChildItem $env:USERPROFILE\.hermes\skills
```

## 6. About skills (and why there's no "install everything" button)

Hermes' skill model is **dynamic**, not "download a package list" :

1. **Bundled** : a base set ships with Hermes itself (file ops, web search, shell, etc.). No extra step needed.
2. **Auto-created** : after complex tasks, Hermes writes new skills into `~/.hermes/skills/` as procedural memory. These accumulate as you use it.
3. **Community** : browse [agentskills.io](https://agentskills.io). Install one from inside Hermes chat with the `/skill add <id>` slash command.
4. **Awesome list** : [`0xNyk/awesome-hermes-agent`](https://github.com/0xNyk/awesome-hermes-agent) curates community skills + tools.

> As of Hermes Agent v0.14.0 there is **no** documented `hermes skill install --all`
> one-liner. Bulk-installing every community skill would be noisy and bloat
> the agent's tool surface. Install per use case — and let Hermes' procedural
> memory grow the rest naturally.

## 7. Install Mission Control

Needs **Node.js 22+** and **pnpm**.

```powershell
# Node 22 via winget (skip if you have it)
winget install -e --id OpenJS.NodeJS.LTS --silent
# Relaunch PowerShell after this, then :
node --version    # should be v22.x

# pnpm
corepack enable
corepack prepare pnpm@latest --activate
```

Clone + install :

```powershell
git clone https://github.com/builderz-labs/mission-control.git $env:USERPROFILE\mission-control
cd $env:USERPROFILE\mission-control
.\install.ps1 -Mode local
```

Docker alternative (lower RAM, prod build) : `docker compose up` from that folder.

## 8. Launch the stack

Two PowerShell windows :

```powershell
# Window 1 — Hermes agent loop
hermes
```

```powershell
# Window 2 — Mission Control web dashboard
cd $env:USERPROFILE\mission-control
pnpm dev
```

Open : <http://localhost:3000/setup>

Create your admin account on first visit. Mission Control's API key shows
in **Settings** after login.

## 9. Wire Mission Control to Hermes

Mission Control supports CrewAI, LangGraph, AutoGen out of the box and
exposes a generic REST adapter. Hermes Agent v0.14.0 exposes an
OpenAI-compatible local proxy.

Best-effort wiring (verify against docs as you go) :

1. Mission Control → Settings → copy the API key.
2. Hermes config (`~/.hermes/config.toml` or via `hermes config`), add :
   ```toml
   [mission_control]
   url = "http://localhost:3000"
   api_key = "PASTE_FROM_MC_SETTINGS"
   ```
3. Restart Hermes. It should appear in Mission Control's agent list within ~30s.

If the exact keys above have drifted, run `hermes config --help` and check
the Mission Control "Connect an agent" page — then update this doc to match
reality.

## 10. Firewall (only if you want Mac access via Tailscale)

By default, Mission Control on `localhost:3000` is HP-only. To open it to your
Mac over Tailscale :

```powershell
# Admin PowerShell required
New-NetFirewallRule -Name 'MissionControl-Tailscale' `
  -DisplayName 'Mission Control (Tailscale mesh)' `
  -Direction Inbound -Protocol TCP -LocalPort 3000 `
  -Action Allow -Profile Private
```

Then from Mac : <http://patoupc:3000/setup>

## Troubleshooting

| Issue | Fix |
|---|---|
| `hermes` not found after install | Relaunch PowerShell. PATH only updates for new sessions. |
| `hermes setup` can't reach Ollama | `Invoke-RestMethod http://localhost:11434/api/tags` — if it hangs, Ollama isn't running or `OLLAMA_HOST` is off |
| Gemma OOMs after adding Hermes + MC | Cut one. Try Docker prod build of MC, or move MC to Toshiba |
| `node --version` shows < 22 after winget | Relaunch PowerShell ; if still wrong, install LTS from https://nodejs.org manually |
| Mission Control port 3000 busy | `$env:PORT=3001; pnpm dev`, or `Get-NetTCPConnection -LocalPort 3000` to see who owns it |
| `corepack` missing | `npm install -g pnpm` as fallback |
| Hermes' `/skill add` errors out | Slash command syntax may have changed — check `hermes` chat help (`/help`) for current syntax |

## Next steps

Once Hermes + Mission Control are running and you can dispatch a task from the
dashboard → see it execute on Hermes → see the result land back :

1. Wire Hermes' OpenAI-compatible local proxy as a LiteLLM backend (see `../litellm/`).
2. Benchmark : same task through Hermes-on-Gemma vs Hermes-on-cloud. Log in `../../benchmarks/`.
3. Document any gotcha in `../../docs/TROUBLESHOOTING.md`.
