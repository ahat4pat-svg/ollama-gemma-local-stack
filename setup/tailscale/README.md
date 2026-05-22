# Tailscale mesh setup

Tailscale gives you a private mesh (no public ports, no router config, no VPN headache) between your Mac (orchestrator), Windows (Ollama server), and Linux (workers). Free for personal use up to 100 devices.

This is how the Mac calls `http://patoupc:11434` and the Ollama box answers — without ever exposing port 11434 to the public internet.

## 1. Install on each machine

| OS | Command |
|---|---|
| **macOS** | `brew install --cask tailscale` (or download : <https://tailscale.com/download/mac>) |
| **Windows** | Download installer : <https://tailscale.com/download/windows> |
| **Linux** | `curl -fsSL https://tailscale.com/install.sh \| sh` |

## 2. Bring each machine onto the tailnet

```bash
# macOS / Linux
sudo tailscale up

# Windows (PowerShell, after install)
tailscale up
```

A browser window opens → log in (Google / Microsoft / GitHub) → machine joins your tailnet. Use the **same** account on all three machines.

## 3. Enable MagicDNS (one-time)

Go to <https://login.tailscale.com/admin/dns> → toggle **MagicDNS** ON.

Each machine is now reachable by its short hostname — `patoupc`, `mister-b`, `mbp` — no IPs to memorize, no `/etc/hosts` to maintain.

## 4. Verify the mesh

From the Mac :

```bash
tailscale status
# Expected : all 3 machines listed as `online`

ping patoupc                           # latency test
curl http://patoupc:11434/api/tags     # Ollama reachable over the mesh?
```

If the `curl` hangs but `ping` works → Windows Firewall is blocking port 11434. See [`../windows/install-ollama-windows.md`](../windows/install-ollama-windows.md) §6.

## 5. (Optional) Lock the tailnet down

In the admin console :

- **ACLs** — restrict who/what can hit port 11434 (e.g. only your Mac can reach the Ollama port on Windows).
- **Key expiry** — set to 180 days on the Windows server so the auth doesn't expire under you.
- **MFA** — require 2FA for re-auth on new devices.

## Troubleshooting

| Issue | Fix |
|---|---|
| Hostname `patoupc` doesn't resolve | MagicDNS not enabled — toggle it at <https://login.tailscale.com/admin/dns> |
| `tailscale status` shows `offline` after Windows sleeps | Disable sleep — see [`../windows/prepare-pc-as-server.md`](../windows/prepare-pc-as-server.md) §6 |
| Mac can ping `patoupc` but `curl :11434` hangs | Windows Firewall — see [`../windows/install-ollama-windows.md`](../windows/install-ollama-windows.md) §6 |
| Auth expired on the Windows server | `tailscale up --reset` in PowerShell, re-auth in browser |

---

Once the mesh is up and the Ollama box answers from the Mac, head to [`../litellm/`](../litellm/) to put a proxy in front so your scripts can talk to it like the OpenAI API.
