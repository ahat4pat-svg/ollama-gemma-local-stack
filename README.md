# Ollama + Gemma Local AI Worker Stack

> A complete local AI worker stack built on consumer hardware.
> Ollama + Gemma + Tailscale mesh + LiteLLM routing.
> Runs productized AI services with 100% margin on a single 16 GB consumer machine.

**Built and documented while productizing AI services for AHat4Pat Automations.**

Single HP Pavilion (Windows, 16 GB RAM) dedicated to local LLM serving,
accessible from a Mac orchestrator via Tailscale mesh, routed through LiteLLM.

## Why this exists

The cloud API economy works against indie operators :
- $0.50-$2 per request kills margins on small-ticket AI services
- Rate limits constrain volume
- Vendor lock-in
- Latency from your machine → cloud → back

This stack solves it :
- **Local inference** : zero per-request cost after install
- **Tailscale mesh** : private network across all your machines, no public exposure
- **LiteLLM routing** : same API as OpenAI/Anthropic, drops in for any existing code
- **Multi-OS** : Linux Toshiba, Windows HP, macOS orchestrator — they all just work

## Hardware

The lab I'm building this on :

| Machine | OS | RAM | Role |
|---|---|---|---|
| HP Pavilion | Windows | 16 GB | Dedicated Ollama + Gemma server |
| Toshiba "Mister-B" | Linux | 16 GB | Secondary (scraping, OCR, queue) |
| MacBook Pro | macOS | varies | Orchestrator (Claude Code, Hermès) |
| All linked via | Tailscale | — | private mesh, no public IPs needed |

## What's in this repo

- `setup/windows/` — install Ollama + Gemma on Windows (PowerShell scripts)
- `setup/tailscale/` — mesh setup notes across Mac / Windows / Linux
- `setup/litellm/` — config to route between local + cloud fallback
- `benchmarks/` — real benchmarks on Gemma 3/4 with V-Cache + turbo quant
- `docs/` — step-by-step guides, screenshots, troubleshooting
- `examples/` — sample workflows : cold-email gen, document summary, scraping pipeline

## Who this is for

- Indie hackers / freelancers who want to deliver AI services without burning their margin on API calls
- Tinkerers building home AI servers
- Anyone migrating from OpenAI/Anthropic API to local inference
- Folks who want the freedom of running their own stack

## Status

🟢 **Active build** — documenting as I go. Star to follow updates.

---

Built by [Patrick Lemieux](https://github.com/ahat4pat-svg) · AHat4Pat Automations · Trois-Rivières, QC, Canada.

License : MIT.
