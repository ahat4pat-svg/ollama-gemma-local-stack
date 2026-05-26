# Ollama + Gemma — Local AI Worker Stack (16 GB consumer PC)

> A complete local AI worker stack on a **16 GB consumer machine**.
> Ollama + Gemma + Tailscale mesh + LiteLLM routing.
> Designed to run productized AI services with **100% margin** — no cloud bills.

**Built and documented in real time** while productizing AI services
for AHat4Pat Automations. This repo *is* the install journal — including
the bugs, dead ends, and fixes — so the next person doesn't have to figure it out alone.

## The challenge

> *Can a 16 GB consumer PC run real production AI workloads, accessed remotely from a Mac orchestrator, fast enough to deliver $19-$79 AI services in under 12 hours, with margins big enough to make sense?*

This repo answers it, step by step.

## The setup I'm building on

| Machine | OS | RAM | Role |
|---|---|---|---|
| **HP Pavilion** | Windows | **16 GB** | Dedicated Ollama + Gemma server |
| Toshiba "Mister-B" | Linux | 16 GB | Secondary (scraping, OCR, queue) |
| MacBook Pro | macOS | varies | Orchestrator (Claude Code, Hermès, dispatch) |
| Linked via | Tailscale | — | Private mesh, no public exposure |

## Stack

- **[Ollama](https://ollama.com)** — local model runtime, Windows native
- **[Gemma](https://ai.google.dev/gemma)** — Google's open model family, runs on 16 GB
- **Optimizations** — turbo quant + V-Cache (KV cache) to squeeze max throughput
- **[Tailscale](https://tailscale.com)** — private mesh between Mac/Win/Linux machines
- **[LiteLLM](https://litellm.ai)** — drop-in OpenAI-compatible proxy, routes local + cloud fallback

## ⚠️ Read this first if you're on a 16 GB machine

**Before installing anything**, clean up your PC and free disk/RAM.
A 16 GB consumer machine has to be smart about space — moving models
to an external drive, disabling Windows bloat, etc.

👉 [`setup/windows/prepare-pc-as-server.md`](setup/windows/prepare-pc-as-server.md)

Once your machine is prepped, then run the install.

## What's in this repo

- [`setup/windows/prepare-pc-as-server.md`](setup/windows/prepare-pc-as-server.md) — **start here** : prep the PC (disk, RAM, services, power)
- [`setup/windows/install.ps1`](setup/windows/install.ps1) — automated Ollama + Gemma 4 install (Flash Attention, KV cache, env vars)
- [`setup/windows/install-ollama-windows.md`](setup/windows/install-ollama-windows.md) — manual step-by-step install guide (read alongside the script)
- [`setup/tailscale/`](setup/tailscale/) — mesh setup notes (Mac / Windows / Linux)
- [`setup/litellm/`](setup/litellm/) — proxy config (local Ollama + cloud fallback)
- [`setup/hermes/`](setup/hermes/) — Hermes Agent + Mission Control on the Mac (orchestrator)
- [`benchmarks/`](benchmarks/) — real numbers : tokens/sec, RAM, throughput on 16 GB
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — issues hit + how they got fixed (grows as I go)
- [`examples/`](examples/) — sample workflows : cold-email gen, document summary, scraping pipeline

## Who this is for

- Indie hackers / freelancers who want to deliver AI services without burning their margin on API calls
- Tinkerers building home AI servers
- Anyone migrating from OpenAI/Anthropic API to local inference
- Anyone who has 16 GB and is curious if it's *actually* enough

## Status

🟢 **Active build, day 1** — documenting as I go. Star the repo to follow updates.

---

Built by [Patrick Lemieux](https://github.com/ahat4pat-svg) · AHat4Pat Automations · Trois-Rivières, QC, Canada.

License : MIT.
