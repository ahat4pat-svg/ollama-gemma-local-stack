# Gemma 4 on 16 GB — Local AI Server Kit: Windows reset and clean

Use this guide when you want to **fully or partially reset an Ollama setup** before reinstalling.
It matches the behavior of [`setup/windows/clean-ollama.ps1`](../setup/windows/clean-ollama.ps1).

## What the cleanup script is for

The cleanup script is meant to help you:

- stop a stale or broken Ollama setup
- clear user-level `OLLAMA_*` environment variables managed by this repo
- remove cached state from the default Windows profile locations
- optionally remove model data, including an external `OLLAMA_MODELS` location if that is where your models live
- prepare for a clean reinstall using the product bootstrap flow

It is **not** meant to strip required networking tools like **Tailscale** from the machine.

## Recommended reset commands

### Light reset (keep model files if possible)

```powershell
.\setup\windows\clean-ollama.ps1
```

What it does:

- stops Ollama processes if they are running
- removes the repo-managed `OLLAMA_*` user variables
- removes common Ollama app/cache/config folders under your Windows profile
- leaves Tailscale alone
- keeps model files unless you explicitly ask to remove them

### Full reset including model storage

```powershell
.\setup\windows\clean-ollama.ps1 -RemoveModels
```

What it adds:

- removes `%USERPROFILE%\.ollama` when used as the model store
- also removes the path referenced by `OLLAMA_MODELS` if that folder exists and points elsewhere, such as an external drive

### Reset and launch the registered uninstaller too

```powershell
.\setup\windows\clean-ollama.ps1 -RemoveModels -RunUninstaller
```

What it adds:

- attempts to find a registered Ollama uninstall entry in the Windows uninstall registry locations
- launches that uninstall command if found and confirmed

## What gets removed

The script targets these locations when present:

- `%LOCALAPPDATA%\Ollama`
- `%APPDATA%\Ollama`
- `%USERPROFILE%\.ollama` *(only with `-RemoveModels`)*
- the directory pointed to by `OLLAMA_MODELS` *(only with `-RemoveModels` and only if different from the default path)*

The script also clears these user environment variables:

- `OLLAMA_HOST`
- `OLLAMA_MODELS`
- `OLLAMA_MAX_LOADED_MODELS`
- `OLLAMA_NUM_PARALLEL`
- `OLLAMA_FLASH_ATTENTION`
- `OLLAMA_KV_CACHE_TYPE`

## What the script intentionally does not remove

- **Tailscale**
- the repository folder itself
- unrelated user folders
- cloud-sync tools such as OneDrive / iCloud / Google Drive
- broader Windows applications or OEM packages

Those items are outside the safe scope of an Ollama reset helper.

## Reclaiming disk space

If you are reclaiming space on a 16 GB Windows machine, do this in order:

1. run the cleanup script with `-RemoveModels` if you want to recover model storage
2. re-run `Audit` mode to verify free space
3. prepare or reconnect the external drive
4. reinstall with `gemma4:e4b` first

Recommended follow-up commands:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Audit
.\setup\windows\bootstrap.ps1 -Mode Prepare -ExternalDrive E:
.\setup\windows\bootstrap.ps1 -Mode Install -Model gemma4:e4b -ExternalDrive E:
```

## External-drive-first reinstall

After a cleanup, prefer re-establishing the external model location before pulling a model again:

```powershell
.\setup\windows\setup-external-drive.ps1 -ExternalDrive E:
```

That command recreates the external-drive folder layout and sets `OLLAMA_MODELS` to the new external model path.

## Conservative optimization note

If you were previously experimenting with KV cache or Flash Attention env vars, the reset script clears them so the reinstall can start clean.
This is intentional: optimization flags should be reintroduced deliberately and only when the installed Ollama version actually supports them.
