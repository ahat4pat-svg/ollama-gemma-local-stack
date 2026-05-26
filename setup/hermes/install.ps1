# Hermes Agent install — Windows (HP Pavilion, 16 GB)
# Run as a normal user (NOT administrator). Each step prints what it's doing.
# Stop and inspect if something looks off.
#
# WHAT THIS INSTALLS :
#   - Hermes Agent itself (NousResearch/hermes-agent v0.14.0+)
#   - 85 bundled skills (installed automatically by Nous' installer)
#   - Wires Hermes to local Ollama on http://localhost:11434
#   - Sets up the Kanban task board (~/.hermes/kanban.db)
#
# WHAT YOU GET TO LAUNCH AFTER :
#   - `hermes`                 → interactive chat
#   - `hermes dashboard`       → built-in web UI on http://127.0.0.1:9119
#                                (config, sessions, API keys — THIS is Mission Control)
#   - `hermes gateway run`     → dispatcher that picks up Kanban tasks
#   - `hermes kanban list`     → see the task board from CLI
#
# WHAT WE DELIBERATELY DON'T INSTALL :
#   - builderz-labs/mission-control : community alternative dashboard.
#     The NATIVE `hermes dashboard` covers the same use case + understands Hermes
#     directly. Don't run both on the same box — RAM is tight enough at 16 GB.

$ErrorActionPreference = "Stop"

Write-Host "`n=== Hermes Agent install (HP, 16 GB) ===" -ForegroundColor Cyan
Write-Host "This script does NOT need Administrator.`n"

# --- 0. PREREQUISITE CHECK ----------------------------------------------------

Write-Host "[0/6] Prerequisites..." -ForegroundColor Yellow
Write-Host "  Expected on this HP before running :"
Write-Host "    - Ollama installed + running on localhost:11434 (see ../windows/install.ps1)"
Write-Host "    - Gemma 4 pulled (ollama list shows gemma4:e4b or similar)"
$prepped = Read-Host "  All set? (yes/skip)"
if ($prepped -ne 'yes' -and $prepped -ne 'skip') {
    Write-Host "  Stopping. Get Ollama+Gemma running first, then re-run." -ForegroundColor Yellow
    exit
}

# --- 1. Verify Ollama responds ------------------------------------------------

Write-Host "`n[1/6] Verifying Ollama API on localhost..." -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    Write-Host "  OK Ollama API responds. Installed models :" -ForegroundColor Green
    $r.models | ForEach-Object { Write-Host "    - $($_.name)" }
} catch {
    Write-Host "  X Ollama API did NOT respond. Make sure Ollama is running (system tray icon)." -ForegroundColor Red
    Write-Host "    Re-run setup/windows/install.ps1 first."
    exit 1
}

# --- 2. Install Hermes Agent --------------------------------------------------
# Nous' installer pulls Python 3.11, Node 22, ripgrep, ffmpeg, git, then Hermes itself.
# It also syncs all 85 bundled skills into ~/.hermes/skills/ — no extra step needed.

Write-Host "`n[2/6] Installing Hermes Agent (NousResearch)..." -ForegroundColor Yellow
$hermesCmd = Get-Command hermes -ErrorAction SilentlyContinue
if ($hermesCmd) {
    Write-Host "  OK hermes already in PATH : $($hermesCmd.Source)"
    try { & hermes --version } catch { Write-Host "  (hermes --version failed — continuing)" }
} else {
    Write-Host "  Running official installer. Pulls Python 3.11, Node 22, ripgrep, ffmpeg, git."
    Write-Host "  Also syncs 85 bundled skills automatically."
    Write-Host "  This may take 3-8 minutes depending on connection."
    iex (irm https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1)
    Write-Host "  Installer finished." -ForegroundColor Green

    if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
        Write-Host "  IMPORTANT : 'hermes' not yet on PATH in this session." -ForegroundColor Yellow
        Write-Host "  RELAUNCH PowerShell, then re-run this script — it'll skip step [2] and continue."
        exit 0
    }
}

# --- 3. Configure Hermes to use local Ollama ----------------------------------
# Use `hermes setup model` rather than the full wizard — it's the one section
# we actually care about. Wizard asks: provider (pick "ollama"), base_url
# (http://localhost:11434), default model (gemma4:e4b).

Write-Host "`n[3/6] Configure model provider (Ollama on localhost)..." -ForegroundColor Yellow
Write-Host "  When the wizard asks :"
Write-Host "    Provider       : ollama" -ForegroundColor Cyan
Write-Host "    Base URL       : http://localhost:11434" -ForegroundColor Cyan
Write-Host "    Default model  : gemma4:e4b   (or whatever 'ollama list' showed)" -ForegroundColor Cyan
$runSetup = Read-Host "  Run 'hermes setup model' now? (y/skip)"
if ($runSetup -eq 'y') {
    try { & hermes setup model } catch { Write-Host "  hermes setup model errored — note it and rerun." -ForegroundColor Yellow }
} else {
    Write-Host "  Skipped. Run 'hermes setup model' yourself before first chat."
}

# --- 4. Initialize the Kanban task board --------------------------------------

Write-Host "`n[4/6] Initializing Kanban task board (SQLite)..." -ForegroundColor Yellow
$kanbanDb = Join-Path $env:USERPROFILE ".hermes\kanban.db"
if (Test-Path $kanbanDb) {
    Write-Host "  OK Kanban DB already exists : $kanbanDb"
} else {
    try {
        & hermes kanban init
        Write-Host "  OK Kanban initialized at $kanbanDb" -ForegroundColor Green
    } catch {
        Write-Host "  hermes kanban init errored — you can rerun later." -ForegroundColor Yellow
    }
}

# --- 5. Confirm bundled skills are loaded -------------------------------------

Write-Host "`n[5/6] Verifying bundled skills..." -ForegroundColor Yellow
try {
    $skillsOut = & hermes skills list 2>&1 | Out-String
    $summary = ($skillsOut -split "`n" | Where-Object { $_ -match 'builtin.*enabled' } | Select-Object -Last 1).Trim()
    if ($summary) {
        Write-Host "  $summary"
    } else {
        Write-Host "  (skills listed — see 'hermes skills list' for the table)"
    }
} catch {
    Write-Host "  Couldn't list skills — run 'hermes skills list' manually." -ForegroundColor Yellow
}

# --- 6. Launch instructions ---------------------------------------------------

Write-Host "`n[6/6] Done. To launch the stack :" -ForegroundColor Yellow
@"

  PowerShell window 1 — Hermes chat (interactive) :
    hermes

  PowerShell window 2 — Mission Control web dashboard (built-in, native to Hermes) :
    hermes dashboard
    # Opens your browser to http://127.0.0.1:9119
    # Manages config, sessions, API keys. Add '--tui' to embed chat in the browser too.

  PowerShell window 3 (optional) — Kanban task dispatcher :
    hermes gateway run
    # Foreground mode. Picks up tasks from the Kanban board and dispatches them.
    # For 'install as Windows service' instead : hermes gateway install   (may need admin)

  Useful commands :
    hermes kanban create -t "First task" -b default   # create a task
    hermes kanban list                                # see the board
    hermes skills list                                # show all 85 bundled skills
    hermes status                                     # health check
    hermes doctor                                     # diagnose config issues

  Log any issue in docs\TROUBLESHOOTING.md.

"@ | Write-Host

Write-Host "=== Install script done. Read output above for any errors. ===" -ForegroundColor Cyan
