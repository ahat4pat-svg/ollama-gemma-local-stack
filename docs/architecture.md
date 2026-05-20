# Gemma 4 on 16 GB — Local AI Server Kit architecture

## Product vision

**Gemma 4 on 16 GB — Local AI Server Kit** is a guided setup assistant for turning a practical Windows PC into a local AI server that can be accessed from other trusted machines.

The repository is intentionally designed as a **product skeleton**:

- one main entrypoint
- guided scripts instead of long copy/paste sessions
- safe defaults for 16 GB machines
- external-drive-first storage planning
- explicit documentation for what is automated and what still needs human confirmation

## Product promise

The product does **not** promise miracle performance from a 16 GB Windows machine.
Instead, it offers a repeatable path to:

1. audit what the PC can realistically support
2. prepare the machine without breaking required services
3. install or reset Ollama cleanly
4. default to a realistic Gemma 4 model
5. capture test and benchmark results for later iteration

## User flow

Recommended flow:

1. **Audit** the machine
2. **Prepare** the machine and external storage
3. **Install** Ollama and the default model
4. **Test** the stack locally and across Tailscale
5. **Benchmark** optional or experimental models

Primary commands:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Audit
.\setup\windows\bootstrap.ps1 -Mode Prepare -ExternalDrive E:
.\setup\windows\bootstrap.ps1 -Mode Install -Model gemma4:e4b -ExternalDrive E:
.\setup\windows\bootstrap.ps1 -Mode Test -Model gemma4:e4b
.\setup\windows\bootstrap.ps1 -Mode Benchmark -Model gemma4:26b
```

## Main modes

### Audit

Purpose:

- inspect the machine before making changes
- show RAM and disk readiness
- detect Ollama / Tailscale presence
- surface current `OLLAMA_*` settings
- produce a simple report under `reports/`

Audit mode is read-only.

### Prepare

Purpose:

- set up the external-drive layout
- keep storage organized for models, reports, exports, and workspace data
- optionally run an Ollama cleanup/reset before reinstalling
- preserve required network pieces such as **Tailscale**

Prepare mode is where the repo starts to feel like a product assistant instead of a manual notebook.

### Install

Purpose:

- install or detect Ollama
- apply conservative user-level environment settings
- pull the selected Gemma 4 model
- run a local smoke prompt

Default target:

- **`gemma4:e4b`**

Optional experimental target:

- **`gemma4:26b`**

### Test

Purpose:

- check local API availability
- verify one model can answer a prompt
- confirm Tailscale CLI visibility when used as part of the local server role

### Benchmark

Purpose:

- measure pull time, generation time, and free-space changes for a chosen model
- keep a written result file under `benchmarks/results/`
- compare the safe default against an experimental larger option

## Model positioning

### `gemma4:e4b` is the default

Why:

- it is the practical starting point for a **16 GB Windows machine**
- it fits the product goal of “likely to work first”
- it reduces the chance of a frustrating first-run experience

### `gemma4:26b` is experimental

Why:

- it may still be worth testing on a clean machine
- it is useful as a benchmark or stretch target
- it should not be marketed in this repo as the default 16 GB experience

The product story is therefore:

- **E4B first**
- **26B only when explicitly chosen for testing**

## Safe-by-default principles

1. **Preserve important services**
   - Do not remove Tailscale just because the machine is being cleaned up.
   - Remote access and private networking are part of the intended product use.

2. **Confirmation before destructive cleanup**
   - Removing model data or existing Ollama state should require explicit confirmation.

3. **Prefer user-level environment settings first**
   - Use persistent user variables for the local server kit where possible.

4. **Keep the first run simple**
   - The initial target is a working `gemma4:e4b` install, not an aggressive tuning experiment.

5. **Document uncertainty honestly**
   - When an optimization depends on Ollama version, model backend, or future support, say so.

## External-drive-first strategy

For many 16 GB Windows machines, disk pressure matters as much as RAM.
The product therefore treats external storage as a first-class part of the setup.

Recommended layout:

```text
E:\gemma4-local-ai-server-kit\
├─ ollama-models\
├─ workspace\
├─ datasets\
├─ reports\
├─ exports\
├─ backups\
└─ cloud-sync\
```

What goes there first:

- Ollama model storage
- benchmark results and reports
- exported outputs
- workspace inputs and datasets

What stays on the system drive:

- Windows itself
- Tailscale
- the Ollama application binary
- the repository checkout
- normal OS/network components required for the PC to function as a local server

## What is automated vs manually confirmed

### Automated by scripts

- audit report creation
- external drive directory creation
- setting conservative `OLLAMA_*` user env vars
- downloading the Ollama installer when needed
- model pull commands
- local API/generation test calls
- benchmark report generation

### Manually confirmed or intentionally semi-automatic

- deleting existing model stores
- launching the Ollama uninstaller
- firewall changes that require admin rights
- broader Windows cleanup beyond Ollama
- moving personal folders or cloud-sync decisions

This split is intentional.
The product should save time without taking unsafe liberties with a real Windows machine.

## KV cache, Flash Attention, and TurboQuant in the product story

These topics matter, but the repo documents them carefully.

### KV cache / Flash Attention

The local AI server kit acknowledges that:

- KV-cache settings can affect RAM use and throughput
- Flash Attention can help on some supported backends/builds
- Ollama behavior depends on version, platform support, and the selected model/backend

Because of that, the installer treats these as **optional experimental environment flags**, not hard guarantees.

### TurboQuant

TurboQuant is included in the documentation as part of the **optimization roadmap and benchmarking conversation**.
The repo does **not** claim a turnkey “TurboQuant switch” exists in current Ollama releases for every supported setup.

In product terms:

- these are important optimization topics
- they belong in architecture and benchmarking docs
- they must be discussed conservatively until verified on the real target machine

## Output locations

- `reports/` for audit/test/install/reset notes
- `benchmarks/results/` for benchmark runs
- external-drive report/export folders for user machine artifacts

## Why this architecture fits the repository

This architecture keeps the repository practical:

- the docs match the script flow
- the default path uses minimal copy/paste
- the naming is consistent
- the repo can be tested later on a real Windows 16 GB machine without rewriting everything first
