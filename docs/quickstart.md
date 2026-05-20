# Gemma 4 on 16 GB — Local AI Server Kit quickstart

This is the fastest recommended path for a **new 16 GB Windows machine**.
Use the bootstrap script as the one main entrypoint.

## 1. Open PowerShell in the repository

From the repo root:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Audit
```

What it does:

- checks Windows / RAM / disk basics
- reports whether `ollama` and `tailscale` are already present
- shows current `OLLAMA_*` user environment settings
- points out whether an external drive is available for model storage

## 2. Prepare the machine and external drive

If you plan to keep models off `C:`, plug in the external drive first.

```powershell
.\setup\windows\bootstrap.ps1 -Mode Prepare -ExternalDrive E:
```

Prepare mode is designed to be safe by default:

- it re-runs the audit
- it creates the recommended external-drive layout
- it sets `OLLAMA_MODELS` to the external model path
- it offers an **optional** Ollama cleanup/reset step
- it leaves **Tailscale** alone

If you are starting from a previously messy install, read:

- [`windows-reset-and-clean.md`](windows-reset-and-clean.md)

## 3. Install the default model

The default target is **`gemma4:e4b`**.

```powershell
.\setup\windows\bootstrap.ps1 -Mode Install -Model gemma4:e4b -ExternalDrive E:
```

The installer will:

- ensure Ollama is installed or download the official installer
- set conservative user-level environment variables
- optionally apply experimental KV-cache / Flash Attention env vars only if you ask for them
- pull the selected model
- run a local smoke prompt

## 4. Test the stack

```powershell
.\setup\windows\bootstrap.ps1 -Mode Test -Model gemma4:e4b
```

Test mode checks:

- `ollama --version`
- local API response at `http://localhost:11434/api/tags`
- one non-streaming generation request
- Tailscale CLI availability/status if installed

## 5. Optional: benchmark the experimental model

If the machine is clean and you want to try a larger Gemma 4 option:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Benchmark -Model gemma4:26b
```

Treat `gemma4:26b` as an **experimental benchmark/test path** on 16 GB machines.
It may still be useful to try, but the repo does **not** present it as the safe default.

## Recommended order summary

```powershell
.\setup\windows\bootstrap.ps1 -Mode Audit
.\setup\windows\bootstrap.ps1 -Mode Prepare -ExternalDrive E:
.\setup\windows\bootstrap.ps1 -Mode Install -Model gemma4:e4b -ExternalDrive E:
.\setup\windows\bootstrap.ps1 -Mode Test -Model gemma4:e4b
.\setup\windows\bootstrap.ps1 -Mode Benchmark -Model gemma4:26b
```

## Where outputs go

- general reports: `reports/`
- benchmark results: `benchmarks/results/`
- external-drive layout: `E:\gemma4-local-ai-server-kit\...`

## Conservative optimization note

The product docs mention **KV cache**, **Flash Attention**, and **TurboQuant** because they matter to the optimization story.
This repo only applies env vars conservatively and does **not** promise that any specific Ollama build or backend will honor every optimization knob.
