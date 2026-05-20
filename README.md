# Gemma 4 on 16 GB — Local AI Server Kit

> A guided Windows setup assistant for turning a **16 GB PC** into a practical local AI server.
> Built around **Ollama**, **Gemma 4**, **Tailscale**, and an **external-drive-first** storage strategy.

This repository is now organized as a **product-like local server kit** rather than a loose install journal.
The goal is simple: give a 16 GB Windows machine a clear path from audit to cleanup to install to test,
with **one main entrypoint**, conservative defaults, and minimal copy/paste.

## Product focus

**Gemma 4 on 16 GB — Local AI Server Kit** helps you:

- audit a Windows PC before you install anything heavy
- keep important remote-access/network pieces such as **Tailscale** intact
- move AI storage to an **external drive first** when possible
- install or reset **Ollama** cleanly
- default to **`gemma4:e4b`** on 16 GB machines
- try **`gemma4:26b`** as an **experimental benchmark/test option**
- document what is automated vs what still needs user confirmation

## Recommended user flow

The main entrypoint is:

```powershell
.\setup\windows\bootstrap.ps1
```

Recommended path for a new machine:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Audit
.\setup\windows\bootstrap.ps1 -Mode Prepare -ExternalDrive E:
.\setup\windows\bootstrap.ps1 -Mode Install -Model gemma4:e4b -ExternalDrive E:
.\setup\windows\bootstrap.ps1 -Mode Test -Model gemma4:e4b
```

Optional experimental benchmark:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Benchmark -Model gemma4:26b
```

## Safe-by-default product decisions

- **Default model:** `gemma4:e4b`
- **Experimental model:** `gemma4:26b`
- **Tailscale is preserved**, not stripped out during cleanup
- **External storage is recommended first** for models, reports, exports, and workspace data
- Destructive cleanup actions stay **confirmation-based**
- KV cache / Flash Attention / TurboQuant topics are documented **conservatively** and are **not promised as guaranteed Ollama features**

## Repository map

- [`docs/quickstart.md`](docs/quickstart.md) — shortest recommended path for a new user
- [`docs/architecture.md`](docs/architecture.md) — product architecture, modes, principles, automation boundaries
- [`docs/windows-reset-and-clean.md`](docs/windows-reset-and-clean.md) — clean reset workflow for Ollama on Windows
- [`setup/windows/bootstrap.ps1`](setup/windows/bootstrap.ps1) — single main entrypoint
- [`setup/windows/audit.ps1`](setup/windows/audit.ps1) — machine audit and readiness report
- [`setup/windows/setup-external-drive.ps1`](setup/windows/setup-external-drive.ps1) — prepare external-drive-first layout
- [`setup/windows/clean-ollama.ps1`](setup/windows/clean-ollama.ps1) — confirmation-based reset / cleanup
- [`setup/windows/install.ps1`](setup/windows/install.ps1) — install or reconfigure Ollama + pull Gemma 4
- [`setup/windows/test-stack.ps1`](setup/windows/test-stack.ps1) — local API + generation + Tailscale checks
- [`setup/windows/benchmark-model.ps1`](setup/windows/benchmark-model.ps1) — simple benchmark capture for E4B or 26B
- [`setup/windows/install-ollama-windows.md`](setup/windows/install-ollama-windows.md) — manual fallback guide
- [`setup/windows/prepare-pc-as-server.md`](setup/windows/prepare-pc-as-server.md) — preparation checklist for Windows 16 GB machines
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — issues, fixes, and field notes

## What this repo is and is not

This repo is a **guided setup assistant / installer skeleton** for a real local AI server build on Windows.
It is not a claim that every optimization flag, runtime feature, or large-model configuration will work on every 16 GB machine.

In particular:

- `gemma4:e4b` is the safe default target
- `gemma4:26b` is worth trying if you have a clean system, enough free disk, and patience for a slower experiment
- KV cache and Flash Attention may help when supported by your Ollama version and backend
- TurboQuant is part of the product story as a **future optimization topic**, not as a guaranteed toggle this repo can enable today

## Who this is for

- Windows users trying to build a practical home or office local AI server on **16 GB RAM**
- people who want **fewer manual commands** and a clearer install path
- builders who need **Tailscale-connected** access from other machines
- anyone who wants to compare a stable default (`gemma4:e4b`) against an ambitious experiment (`gemma4:26b`)

## Status

This is an evolving product skeleton intended to be tested on a real Windows machine next.
The docs and scripts are designed to be practical first, then iterated from real results.

---

Built by [Patrick Lemieux](https://github.com/ahat4pat-svg) · AHat4Pat Automations · Trois-Rivières, QC, Canada.

License: MIT.
