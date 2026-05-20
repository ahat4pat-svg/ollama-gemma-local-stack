# Manual Windows install fallback for Gemma 4 on 16 GB — Local AI Server Kit

This guide is the manual fallback when you do **not** want to use the main bootstrap path.
The preferred product flow is still:

```powershell
.\setup\windows\bootstrap.ps1 -Mode Install -Model gemma4:e4b -ExternalDrive E:
```

## 1. Install Ollama

Download the official installer:

- <https://ollama.com/download/windows>

Run it, then verify:

```powershell
ollama --version
```

## 2. Set conservative user environment variables

Use user-level variables first so the setup stays predictable.

```powershell
[System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_MAX_LOADED_MODELS', '1', 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_NUM_PARALLEL', '1', 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_MODELS', 'E:\gemma4-local-ai-server-kit\ollama-models', 'User')
```

If you are experimenting and your Ollama version supports it, you can also test optional flags later:

```powershell
[System.Environment]::SetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', '1', 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'q8_0', 'User')
```

Those flags are intentionally **not presented as guaranteed optimizations** for every setup.

After changing env vars, quit and relaunch Ollama from the tray.

## 3. Pull the default model first

```powershell
ollama pull gemma4:e4b
```

Optional experimental benchmark target:

```powershell
ollama pull gemma4:26b
```

## 4. Test locally

```powershell
ollama run gemma4:e4b "Write a 3-line haiku about a Quebec winter morning."
```

## 5. Test over Tailscale

From another trusted machine on your tailnet:

```bash
curl http://YOUR-WINDOWS-HOSTNAME:11434/api/tags
```

Generation example:

```bash
curl http://YOUR-WINDOWS-HOSTNAME:11434/api/generate -d '{
  "model": "gemma4:e4b",
  "prompt": "Hello from another machine on Tailscale.",
  "stream": false
}'
```

## 6. Firewall

Test first. If Windows Firewall blocks access, add a private-profile inbound rule:

```powershell
New-NetFirewallRule -Name "Ollama-Tailscale" `
  -DisplayName "Ollama (Tailscale mesh)" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 11434 `
  -Action Allow `
  -Profile Private
```

## 7. Manual path summary

- prefer an external model path before pulling anything large
- start with `gemma4:e4b`
- use `gemma4:26b` only as an experimental benchmark/test option
- keep Tailscale installed if the machine is meant to stay reachable
