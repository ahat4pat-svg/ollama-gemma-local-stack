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

# --- PREREQUISITE CHECK : did you prep the PC first? --------------------------

Write-Host "PREREQUISITE : have you read setup/windows/prepare-pc-as-server.md ?" -ForegroundColor Yellow
Write-Host "  That guide covers : disk cleanup, RAM freeing, power settings, external drive for models, etc."
Write-Host "  It's important for 16 GB machines — you may not have enough free space otherwise."
$prepped = Read-Host "  Have you prepped the PC (or do you want to skip and proceed anyway)? (yes/skip)"
if ($prepped -ne 'yes' -and $prepped -ne 'skip') {
    Write-Host "  Stopping. Open setup/windows/prepare-pc-as-server.md and follow at least the minimum steps." -ForegroundColor Yellow
    exit
}

# --- CLEAN SLATE : detect existing Ollama and offer a wipe --------------------
#
# Why this exists : the turbo-quant / Flash Attention / KV cache env vars set in
# [0/8] only take effect on a FRESH Ollama process. If Ollama is already
# installed AND was launched before with different (or no) env vars, the safest
# path is to uninstall, wipe models, clear env vars, and start clean. Skip this
# block if this is a first-time install (no `ollama` on PATH).

Write-Host "`n[PRE] Checking for an existing Ollama install..." -ForegroundColor Yellow
$existingOllama = (Get-Command ollama -ErrorAction SilentlyContinue).Source
if ($existingOllama) {
    Write-Host "  Found existing Ollama at $existingOllama" -ForegroundColor Yellow

    $knownVars = @('OLLAMA_HOST','OLLAMA_FLASH_ATTENTION','OLLAMA_KV_CACHE_TYPE','OLLAMA_MAX_LOADED_MODELS','OLLAMA_NUM_PARALLEL','OLLAMA_MODELS')
    Write-Host "  Current Ollama env vars :"
    foreach ($v in $knownVars) {
        $u = [System.Environment]::GetEnvironmentVariable($v, 'User')
        $m = [System.Environment]::GetEnvironmentVariable($v, 'Machine')
        if ($u) { Write-Host "    $v = $u  (User)" }
        elseif ($m) { Write-Host "    $v = $m  (Machine)" }
        else { Write-Host "    $v = (not set)" -ForegroundColor DarkGray }
    }

    try {
        $models = & ollama list 2>$null
        if ($models) { Write-Host "  Currently installed models :" ; Write-Host $models }
    } catch {}

    Write-Host "  → A clean reinstall is recommended so the optimized env vars in [0/8] take effect from first launch."
    $reset = Read-Host "  Uninstall Ollama + wipe models + clear env vars now? (yes/no)"
    if ($reset -eq 'yes') {
        Write-Host "  → Stopping any running Ollama process..."
        Get-Process -Name 'ollama*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        Write-Host "  → Uninstalling Ollama via winget..."
        & winget uninstall --silent --id Ollama.Ollama 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    winget didn't find the package. Open 'Apps & Features' → Ollama → Uninstall manually." -ForegroundColor Yellow
            Read-Host "    Press ENTER once Ollama is uninstalled"
        }

        Write-Host "  → Removing model + cache directories..."
        $modelsDir = [System.Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')
        if (-not $modelsDir) { $modelsDir = [System.Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'Machine') }
        $candidates = @("$env:USERPROFILE\.ollama", $modelsDir) | Where-Object { $_ -and (Test-Path $_) }
        foreach ($d in $candidates) {
            Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    Removed $d"
        }

        Write-Host "  → Clearing old Ollama env vars (User + Machine)..."
        foreach ($v in $knownVars) {
            [System.Environment]::SetEnvironmentVariable($v, $null, 'User')
            [System.Environment]::SetEnvironmentVariable($v, $null, 'Machine')
        }

        Write-Host "  ✓ Clean slate. Re-run this script in a NEW PowerShell window so PATH refreshes." -ForegroundColor Green
        exit
    } else {
        Write-Host "  Keeping existing install. [0/8] will overwrite env vars — you'll restart Ollama in [2/8]." -ForegroundColor Yellow
    }
} else {
    Write-Host "  No existing Ollama detected. Proceeding with a fresh install."
}

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

# --- 4. Pull Gemma 4 E4B (default for 16 GB) ----------------------------------

Write-Host "`n[4/8] Pulling Gemma 4 E4B..." -ForegroundColor Yellow
Write-Host "  Edge 4B (~4 GB on disk) — generalist, fast, fits comfortably alongside KV cache + Windows in 16 GB."
Write-Host "  (The MoE specialist variant exists too — see install-ollama-windows.md if you want to try it later.)"

$gemmaTag = "gemma4:e4b"
Write-Host "  → ollama pull $gemmaTag"
& ollama pull $gemmaTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ Pull failed. The tag '$gemmaTag' may not be published on Ollama's library yet." -ForegroundColor Red
    Write-Host "    Check current Gemma tags here : https://ollama.com/library/gemma"
    Write-Host "    Closest equivalents you can try :"
    Write-Host "      gemma3:4b           — Gemma 3, 4B, generalist"
    Write-Host "      gemma3:4b-it-qat    — Gemma 3, 4B, QAT (better quality at low quant)"
    $fb = Read-Host "    Fall back to 'gemma3:4b' now? (yes/no)"
    if ($fb -eq 'yes') {
        $gemmaTag = "gemma3:4b"
        & ollama pull $gemmaTag
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ✗ Fallback pull also failed. Aborting — fix network/tag and re-run." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  Aborting. Pick a tag from the library and re-run this script." -ForegroundColor Yellow
        Write-Host "  Log the issue in docs/TROUBLESHOOTING.md so the next person isn't stuck."
        exit 1
    }
}

# --- 5. Quick local generation test -------------------------------------------

Write-Host "`n[5/8] Quick local generation test against '$gemmaTag'..." -ForegroundColor Yellow
try {
    $body = @{ model = $gemmaTag; prompt = "Write a 2-line haiku about Quebec winter."; stream = $false } | ConvertTo-Json
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

  Expected : JSON listing the installed model ($gemmaTag).

  Then run a generation from Mac :
    curl http://patoupc:11434/api/generate -d '{
      \"model\": \"$gemmaTag\",
      \"prompt\": \"Hello from Mac to HP via Tailscale.\",
      \"stream\": false
    }'

  Log any issue in docs/TROUBLESHOOTING.md so the next person doesn't waste time.
"@

Write-Host "`n=== Install script done. Read output above for any errors. ===" -ForegroundColor Cyan
