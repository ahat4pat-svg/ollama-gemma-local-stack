# Ollama + Gemma 4 local server install — Windows (HP Pavilion 16 GB)
# Run as a normal user (NOT administrator) unless noted.
# Each step prints what it's doing. Stop and inspect if something looks off.
#
# IMPORTANT : Section [0/8] below sets environment variables that MUST be in place
# BEFORE Ollama first launches a model. They enable Flash Attention + KV-cache
# quantization + memory caps suited for a 16 GB machine. If you skip these,
# Ollama runs but uses way more RAM than necessary and may OOM with Gemma 4 MoE.

$ErrorActionPreference = "Stop"

Write-Host "`n=== Ollama + Gemma 4 local server install (HP, 16 GB) ===" -ForegroundColor Cyan
Write-Host "This script does NOT need Administrator (except step 6 — firewall — which is optional).`n"

# --- 0. CRITICAL pre-install env vars (turbo quant + KV cache + RAM caps) -----

Write-Host "[0/8] Setting pre-install env vars (Flash Attention + KV-cache quant + RAM caps)..." -ForegroundColor Yellow
Write-Host "  These must be set BEFORE Ollama first runs a model."

$envVars = @{
    # Tailscale binding (Mac orchestrator can call HP)
    'OLLAMA_HOST' = '0.0.0.0:11434'
    # Flash Attention : faster + lower memory KV cache
    'OLLAMA_FLASH_ATTENTION' = '1'
    # Quantize KV cache to q8_0 (good balance — q4_0 saves more RAM but quality drop)
    'OLLAMA_KV_CACHE_TYPE' = 'q8_0'
    # Keep only 1 model loaded at a time (16 GB constraint)
    'OLLAMA_MAX_LOADED_MODELS' = '1'
    # Process 1 request at a time (RAM-friendly on 16 GB)
    'OLLAMA_NUM_PARALLEL' = '1'
    # Where to store models (default is %USERPROFILE%\.ollama\models — change here if you want another drive)
    # 'OLLAMA_MODELS' = 'D:\ollama-models'
}

foreach ($k in $envVars.Keys) {
    [System.Environment]::SetEnvironmentVariable($k, $envVars[$k], 'User')
    Set-Item -Path "env:$k" -Value $envVars[$k]
    Write-Host "  ✓ $k = $($envVars[$k])"
}

Write-Host "  Note : Ollama needs to be RESTARTED for env vars to take effect (step 3 will guide you)."

# --- 1. Check or install Ollama -----------------------------------------------

Write-Host "`n[1/8] Checking Ollama..." -ForegroundColor Yellow
$ollamaPath = (Get-Command ollama -ErrorAction SilentlyContinue).Source
if (-not $ollamaPath) {
    Write-Host "  Ollama not found. Downloading the official installer..."
    $url = "https://ollama.com/download/OllamaSetup.exe"
    $out = "$env:TEMP\OllamaSetup.exe"
    Invoke-WebRequest -Uri $url -OutFile $out
    Write-Host "  Installer downloaded. Launching..."
    Start-Process -FilePath $out -Wait
    Write-Host "  Installer finished. You may need to relaunch this PowerShell session for `ollama` to be in PATH." -ForegroundColor Yellow
    Write-Host "  Then re-run this script." -ForegroundColor Yellow
    exit
} else {
    Write-Host "  Ollama already installed at $ollamaPath"
    & ollama --version
}

# --- 2. Restart Ollama so env vars from [0] take effect -----------------------

Write-Host "`n[2/8] You must quit Ollama from the system tray and relaunch it now." -ForegroundColor Yellow
Write-Host "  (Right-click Ollama icon in system tray -> Quit, then launch Ollama from Start Menu.)"
Read-Host "  Press ENTER once you've done this"

# --- 3. Verify env vars are picked up + API responds --------------------------

Write-Host "`n[3/8] Verifying Ollama API + env vars..." -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    Write-Host "  ✓ Ollama API responds on localhost." -ForegroundColor Green
} catch {
    Write-Host "  ✗ Ollama API did NOT respond. Make sure Ollama is running (system tray icon)." -ForegroundColor Red
    Write-Host "    Restart it then re-run this script from step [3]."
    exit 1
}

# --- 4. Pull Gemma 4 model ----------------------------------------------------

Write-Host "`n[4/8] Pulling Gemma 4 model..." -ForegroundColor Yellow
Write-Host "  Two options for Gemma 4 :"
Write-Host "    A) gemma4:e4b      → Edge 4B (~4 GB), fast, fits comfortably in 16 GB"
Write-Host "    B) gemma4:moe      → Mixture-of-Experts (~26 GB on disk, only ~4.3B params active in RAM)"
Write-Host "  MoE is a SPECIALIST model — better at deep reasoning, but slower to start (loads on demand)."
Write-Host "  E4B is a generalist — faster, simpler, good first choice."
Write-Host ""
$choice = Read-Host "  Pull (a) E4B / (b) MoE / (both) / (skip) ?"
switch ($choice) {
    "a" { & ollama pull gemma4:e4b }
    "b" { & ollama pull gemma4:moe }
    "both" {
        & ollama pull gemma4:e4b
        & ollama pull gemma4:moe
    }
    "skip" { Write-Host "  Skipped. Run later : ollama pull gemma4:e4b" }
    default { Write-Host "  Unknown choice, defaulting to E4B" ; & ollama pull gemma4:e4b }
}

# NOTE : as of writing, if `gemma4:e4b` tag doesn't exist on Ollama library yet,
# fall back to the closest available :
#   ollama pull gemma3:4b
# Document any model-tag issue in docs/TROUBLESHOOTING.md

# --- 5. Quick local generation test -------------------------------------------

Write-Host "`n[5/8] Quick local generation test..." -ForegroundColor Yellow
$model = Read-Host "  Which model tag to test? (default: gemma4:e4b)"
if (-not $model) { $model = "gemma4:e4b" }
try {
    $body = @{ model = $model; prompt = "Write a 2-line haiku about Quebec winter."; stream = $false } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 90
    Write-Host "  ✓ Model responded :" -ForegroundColor Green
    Write-Host "    $($resp.response)"
} catch {
    Write-Host "  ✗ Generation failed : $_" -ForegroundColor Red
    Write-Host "    Possible: model tag doesn't exist, check 'ollama list' and try a different tag."
}

# --- 6. Optional : open Windows Firewall port 11434 (Private profile) ---------

Write-Host "`n[6/8] Windows Firewall rule for port 11434..." -ForegroundColor Yellow
$openFw = Read-Host "  Open port 11434 in Windows Firewall (Private profile)? Needs Administrator. (y/n)"
if ($openFw -eq 'y' -or $openFw -eq 'Y') {
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "  This step needs Administrator. Run this in an elevated PowerShell :" -ForegroundColor Yellow
            Write-Host "    New-NetFirewallRule -Name 'Ollama-Tailscale' -DisplayName 'Ollama (Tailscale mesh)' -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow -Profile Private"
        } else {
            New-NetFirewallRule -Name 'Ollama-Tailscale' -DisplayName 'Ollama (Tailscale mesh)' -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow -Profile Private | Out-Null
            Write-Host "  ✓ Firewall rule added." -ForegroundColor Green
        }
    } catch {
        Write-Host "  Firewall rule add failed : $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Skipped firewall (Tailscale mesh is private — usually fine without)."
}

# --- 7. Tailscale status ------------------------------------------------------

Write-Host "`n[7/8] Tailscale status..." -ForegroundColor Yellow
$tailscalePath = (Get-Command tailscale -ErrorAction SilentlyContinue).Source
if ($tailscalePath) {
    & tailscale status | Select-Object -First 10
} else {
    Write-Host "  Tailscale CLI not in PATH. Install from https://tailscale.com/download/windows."
}

# --- 8. Final smoke test from another machine ---------------------------------

Write-Host "`n[8/8] Final smoke test instructions" -ForegroundColor Yellow
Write-Host @"
  From your Mac (orchestrator), run :
    curl http://patoupc:11434/api/tags
  or with IP :
    curl http://100.111.6.54:11434/api/tags

  Expected : JSON listing the installed models (gemma4:e4b and/or gemma4:moe).

  Then run a generation from Mac :
    curl http://patoupc:11434/api/generate -d '{
      \"model\": \"gemma4:e4b\",
      \"prompt\": \"Hello from Mac to HP via Tailscale.\",
      \"stream\": false
    }'

  Log any issue in docs/TROUBLESHOOTING.md so the next person doesn't waste time.
"@

Write-Host "`n=== Install script done. Read output above for any errors. ===" -ForegroundColor Cyan
