# Prepare a Windows 16 GB PC for Gemma 4 on 16 GB — Local AI Server Kit

Before you install Ollama or pull models, prepare the machine so the first run is stable.
This guide focuses on the product realities of a 16 GB Windows server build:

- audit first
- preserve required system/network pieces like **Tailscale**
- move heavy AI storage to an **external drive first**
- keep cleanup actions practical and reversible where possible

## Recommended order

Start with the main entrypoint:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Audit
.\setup\windows\bootstrap.ps1 -Mode Prepare -ExternalDrive E:
```

If you want a fully manual path, use the checklist below.

---

## 1. Audit the machine before cleanup

What to check first:

- free disk on `C:`
- idle RAM available
- whether Ollama is already installed
- whether Tailscale is installed and needed for your mesh
- whether an external drive is available for models and workspace data

You can capture this with:

```powershell
.\setup\windows\audit.ps1
```

---

## 2. Clean up disk space without breaking the server role

### 2.1 Built-in Windows cleanup

```powershell
# Run as Administrator
cleanmgr /sageset:1
cleanmgr /sagerun:1
```

Safe candidates usually include:

- Temporary Files
- Recycle Bin
- Windows Update Cleanup
- Delivery Optimization Files

### 2.2 Disable hibernation if you need space back

```powershell
# Run as Administrator
powercfg /hibernate off
```

On a 16 GB machine this can free a large file from `C:`.

### 2.3 Remove apps you know you do not need

```powershell
appwiz.cpl
```

Focus on unused OEM tools, game launchers, and other non-essential software.
Do **not** strip required remote-access/network tooling if the PC is meant to remain reachable.

---

## 3. Preserve Tailscale and other required access pieces

For this repo, **Tailscale is expected to stay** if the Windows machine acts as a local AI server for other devices.

Keep enabled if relevant:

- Tailscale
- Ollama startup entry (once installed)
- any essential remote admin tool you actually depend on

Be cautious about “cleanup” advice that disables everything indiscriminately.

---

## 4. External-drive-first storage strategy

For a 16 GB build, assume model files and AI workspace data should live off the system drive whenever possible.

Use the helper script:

```powershell
.\setup\windows\setup-external-drive.ps1 -ExternalDrive E:
```

That script creates:

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

It also sets `OLLAMA_MODELS` to the external model path.

---

## 5. Reduce startup clutter

Open Task Manager → **Startup** and disable apps you do not want consuming RAM at boot.

Candidates often include:

- Teams
- Spotify
- Discord
- OEM updaters you do not use
- other consumer apps unrelated to the local server role

Keep anything necessary for the machine’s real role.

---

## 6. Keep the machine awake like a server

```powershell
powercfg /setactive SCHEME_MIN
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
```

Also review the lid-close action if you are using a laptop as a closed-lid local server.

---

## 7. Optional Ollama reset before reinstall

If the machine already has a messy or partially working Ollama install, use:

```powershell
.\setup\windows\clean-ollama.ps1
```

For a deeper reset including model storage:

```powershell
.\setup\windows\clean-ollama.ps1 -RemoveModels
```

Detailed guidance:

- [`../../docs/windows-reset-and-clean.md`](../../docs/windows-reset-and-clean.md)

---

## 8. Install path after preparation

Once the machine is ready, install the default model first:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Install -Model gemma4:e4b -ExternalDrive E:
```

Then test:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Test -Model gemma4:e4b
```

Only after that should you try the experimental benchmark path:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Benchmark -Model gemma4:26b
```

---

## 9. Conservative optimization note

KV cache, Flash Attention, and TurboQuant matter to the long-term optimization story,
but this repo does **not** treat them as guaranteed wins on every Ollama build.

The safe approach is:

1. get `gemma4:e4b` working first
2. record baseline results
3. only then test optional optimization flags and the experimental `gemma4:26b` path
