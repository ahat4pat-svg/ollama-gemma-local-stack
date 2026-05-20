# Install Ollama + Gemma on Windows (HP Pavilion, 16 GB)

Step-by-step PowerShell guide.

## 1. Install Ollama

Download fresh installer : <https://ollama.com/download/windows>

Run installer. After install, Ollama icon should appear in System Tray.

Verify in PowerShell :

```powershell
ollama --version
```

## 2. Configure Ollama to listen on Tailscale (not just localhost)

By default Ollama only listens on `127.0.0.1:11434`. To allow your Mac (orchestrator) to call it via Tailscale, expose it on all interfaces :

```powershell
# Set environment variable (machine-level, persistent across reboots)
[System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', 'Machine')
```

**Then quit and relaunch Ollama** (right-click system tray icon → Quit, then launch from Start menu).

Verify :

```powershell
netstat -an | findstr 11434
# Expected output : 0.0.0.0:11434 LISTENING
```

## 3. Pull Gemma model

For a 16 GB RAM machine, sweet spot :

```powershell
# Gemma 4 (latest, check Ollama library for exact tag)
ollama pull gemma3:4b
# or if available :
# ollama pull gemma3:12b   # Q4 quantization at 12B fits in 16 GB tight but works
```

Check what's installed :

```powershell
ollama list
```

## 4. Test locally

```powershell
ollama run gemma3:4b "Write a 3-line haiku about a Quebec winter morning."
```

## 5. Test from another machine on Tailscale

From your Mac terminal :

```bash
curl http://patoupc:11434/api/tags
```

Should return JSON listing your installed models.

Generation test :

```bash
curl http://patoupc:11434/api/generate -d '{
  "model": "gemma3:4b",
  "prompt": "Hello from Mac to HP via Tailscale.",
  "stream": false
}'
```

## 6. Firewall

Tailscale traffic is private mesh, but Windows Firewall may still need to allow Ollama. Test from Mac first — if it doesn't respond, add a Windows Firewall inbound rule for port 11434 (only from Tailscale interface).

```powershell
# Open inbound for port 11434 (private profile)
New-NetFirewallRule -Name "Ollama-Tailscale" `
  -DisplayName "Ollama (Tailscale mesh)" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 11434 `
  -Action Allow `
  -Profile Private
```

## Troubleshooting

| Issue | Fix |
|---|---|
| `OLLAMA_HOST` doesn't stick after reboot | Use `SetEnvironmentVariable(...'Machine')` not `'User'` |
| Curl from Mac hangs | Restart Ollama after env var change; check Windows Firewall |
| Model download super slow | Ollama uses HTTP/2 with CDN. Try a different network, or `ollama pull` again — it resumes |
| Out of memory at 12B model | Drop to 4B Q8, or 12B Q4 specifically (`gemma3:12b-instruct-q4_K_M`) |
| Tailscale hostname `patoupc` doesn't resolve from Mac | Make sure MagicDNS is enabled in Tailscale admin (https://login.tailscale.com/admin/dns) |

## Next steps

Once Ollama + Gemma is running and accessible from Mac :

1. Add to LiteLLM config (see `../litellm/`)
2. Update your scripts to route simple queries to local
3. Benchmark : run the same job through OpenRouter Claude vs Gemma local — compare quality
4. Document throughput : how many requests per minute can the 16 GB box handle?
