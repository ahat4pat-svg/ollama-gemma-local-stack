# Hermes Agent + Mission Control setup (HP, runs alongside Ollama)

Install [Hermes Agent](https://github.com/NousResearch/hermes-agent)
(Nous Research's self-improving AI agent, v0.14.0+) on the HP, wired
to your local Ollama+Gemma via loopback, with
[Mission Control](https://github.com/builderz-labs/mission-control)
as the local web dashboard.

- **One-shot script** : [`install.ps1`](install.ps1)
- **Manual guide** : [`install-hermes-windows.md`](install-hermes-windows.md)

Quick start (from PowerShell on the HP, NOT as Administrator) :

```powershell
.\setup\hermes\install.ps1
```

Once installed, launch in two PowerShell windows :

```powershell
# Window 1
hermes

# Window 2
cd $env:USERPROFILE\mission-control
pnpm dev
```

Then open <http://localhost:3000/setup> and work with Hermes directly
from Mission Control.

**About skills** : Hermes ships with a bundled base set, auto-creates more as
it runs (procedural memory under `~/.hermes/skills/`), and lets you import
community skills from [agentskills.io](https://agentskills.io) via the
`/skill add` slash command. There is no documented "install everything"
one-liner as of v0.14.0 — install per use case.

**RAM warning (16 GB box)** : Hermes (~0.5 GB) + Mission Control dev mode
(~0.8 GB) on top of Ollama + Gemma 4 E4B (~5 GB) is workable but tight.
See the manual guide for the full RAM table and mitigation options.
