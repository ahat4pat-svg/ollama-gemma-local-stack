# Ollama + Gemma local server install — Windows (HP Pavilion 16 GB)
# Run as a normal user (NOT administrator) unless noted.
# Each step prints what it's doing. Stop and inspect if something looks off.

$ErrorActionPreference = "Stop"

Write-Host "`n=== Ollama + Gemma local server install ===" -ForegroundColor Cyan
Write-Host "Target machine : HP Pavilion (Windows, 16 GB RAM)"
Write-Host "This script does NOT need Administrator (except step 5 — firewall — which is optional).`n"

# --- 1. Check or install Ollama -----------------------------------------------

Write-Host "[1/7] Checking Ollama..." -ForegroundColor Yellow
$ollamaPath = (Get-Command ollama -ErrorAction SilentlyContinue).Source
if (-not $ollamaPath) {
    Write-Host "  Ollama not found. Downloading the official installer..."
    $url = "https://ollama.com/download/OllamaSetup.exe"
    $out = "$env:TEMP\OllamaSetup.exe"
    Invoke-WebRequest -Uri $url -OutFile $out
    Write-Host "  Installer downloaded to $out. Launching..."
    Start-Process -FilePath $out -Wait
    Write-Host "  Installer finished. You may need to relaunch this script after Ollama is fully installed." -ForegroundColor Yellow
} else {
    Write-Host "  Ollama already installed at $ollamaPath"
    & ollama --version
}

# --- 2. Configure Ollama to listen on Tailscale -------------------------------

Write-Host "`n[2/7] Configuring Ollama to listen on 0.0.0.0:11434 (so Mac via Tailscale can call it)..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', 'User')
$env:OLLAMA_HOST = '0.0.0.0:11434'
Write-Host "  OLLAMA_HOST set to 0.0.0.0:11434 (User scope, persistent)."
Write-Host "  NOTE : you must QUIT Ollama in system tray and relaunch it for this to take effect."

# --- 3. Pull Gemma model ------------------------------------------------------

Write-Host "`n[3/7] Pulling Gemma model..." -ForegroundColor Yellow
Write-Host "  We'll start with gemma3:4b (safe on 16 GB). Bigger models can be pulled later."
$pullModel = Read-Host "  Pull gemma3:4b now? (y/n)"
if ($pullModel -eq 'y' -or $pullModel -eq 'Y') {
    & ollama pull gemma3:4b
} else {
    Write-Host "  Skipped pull. Run manually : ollama pull gemma3:4b"
}

# --- 4. Quick local test ------------------------------------------------------

Write-Host "`n[4/7] Quick local test (Ollama answering on localhost)..." -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    Write-Host "  ✓ Ollama API responds on localhost. Models installed :" -ForegroundColor Green
    $r.models | ForEach-Object { Write-Host "    - $($_.name) ($([Math]::Round($_.size/1GB, 2)) GB)" }
} catch {
    Write-Host "  ✗ Ollama API did NOT respond on localhost." -ForegroundColor Red
    Write-Host "    Make sure Ollama is running (check system tray)."
    Write-Host "    If you just installed Ollama or changed OLLAMA_HOST, quit it + relaunch from Start menu."
}

# --- 5. Open Windows Firewall (optional — Tailscale traffic is private mesh) --

Write-Host "`n[5/7] Windows Firewall rule for Ollama port 11434..." -ForegroundColor Yellow
$openFw = Read-Host "  Open port 11434 in firewall (Private profile only)? Needs Administrator. (y/n)"
if ($openFw -eq 'y' -or $openFw -eq 'Y') {
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "  This step needs Administrator. Skipping. Run these commands in an elevated PowerShell :" -ForegroundColor Yellow
            Write-Host "    New-NetFirewallRule -Name 'Ollama-Tailscale' -DisplayName 'Ollama (Tailscale mesh)' -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow -Profile Private"
        } else {
            New-NetFirewallRule -Name 'Ollama-Tailscale' -DisplayName 'Ollama (Tailscale mesh)' -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow -Profile Private | Out-Null
            Write-Host "  ✓ Firewall rule added." -ForegroundColor Green
        }
    } catch {
        Write-Host "  Firewall rule add failed : $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Skipped firewall. Tailscale traffic is private mesh — usually fine without explicit rule."
}

# --- 6. Tailscale check -------------------------------------------------------

Write-Host "`n[6/7] Tailscale check..." -ForegroundColor Yellow
$tailscalePath = (Get-Command tailscale -ErrorAction SilentlyContinue).Source
if ($tailscalePath) {
    Write-Host "  Tailscale CLI found. Running status..."
    & tailscale status | Select-Object -First 10
} else {
    Write-Host "  Tailscale CLI not in PATH. Install from https://tailscale.com/download/windows if needed."
}

# --- 7. Final smoke test from another machine ---------------------------------

Write-Host "`n[7/7] Final smoke test instructions" -ForegroundColor Yellow
Write-Host @"
  From your Mac (orchestrator), run :
    curl http://patoupc:11434/api/tags
  or with IP :
    curl http://100.111.6.54:11434/api/tags

  Expected : JSON listing the installed models.

  If that works, you can run a generation from Mac :
    curl http://patoupc:11434/api/generate -d '{
      \"model\": \"gemma3:4b\",
      \"prompt\": \"Hello from Mac to HP via Tailscale.\",
      \"stream\": false
    }'

  Document any issue in docs/TROUBLESHOOTING.md so the next person doesn't waste time on it.
"@

Write-Host "`n=== Install script done. Read output above for any errors. ===" -ForegroundColor Cyan
