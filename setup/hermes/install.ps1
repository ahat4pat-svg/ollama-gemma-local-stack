# Hermes Agent + Mission Control install — Windows (HP Pavilion, 16 GB)
# Run as a normal user (NOT administrator). Each step prints what it's doing.
# Stop and inspect if something looks off.
#
# Targets :
#   - Hermes Agent (NousResearch/hermes-agent)        → %USERPROFILE%\.hermes + `hermes` CLI
#   - Mission Control (builderz-labs/mission-control) → %USERPROFILE%\mission-control, port 3000
#   - Bundled skills come with Hermes ; user-extensible from agentskills.io
#
# ARCHITECTURE NOTE :
#   On the HP, Ollama is already running on 0.0.0.0:11434 (see ../windows/).
#   Hermes will call it via loopback (http://localhost:11434), no Tailscale hop.
#   Mission Control runs on http://localhost:3000.
#
# RAM NOTE (16 GB) :
#   Hermes runtime ~ 200-500 MB. Mission Control (Next.js dev) ~ 400-800 MB.
#   Gemma 4 E4B uses ~ 4-5 GB when loaded. Tight but workable. If Gemma OOMs,
#   suspect Hermes/Mission-Control first — drop one to free RAM.

$ErrorActionPreference = "Stop"

Write-Host "`n=== Hermes Agent + Mission Control install (HP, 16 GB) ===" -ForegroundColor Cyan
Write-Host "This script does NOT need Administrator.`n"

# --- 0. PREREQUISITE CHECK ----------------------------------------------------

Write-Host "[0/9] Prerequisites..." -ForegroundColor Yellow
Write-Host "  Expected on this HP before running :"
Write-Host "    - Ollama installed + running on localhost:11434 (see ../windows/install.ps1)"
Write-Host "    - Gemma 4 pulled (ollama list shows gemma4:e4b or similar)"
Write-Host "    - Tailscale connected (optional, only needed if you also want Mac access)"
$prepped = Read-Host "  All set? (yes/skip)"
if ($prepped -ne 'yes' -and $prepped -ne 'skip') {
    Write-Host "  Stopping. Get Ollama+Gemma running first, then re-run." -ForegroundColor Yellow
    exit
}

# --- 1. Verify Ollama is reachable on loopback --------------------------------

Write-Host "`n[1/9] Verifying Ollama API on localhost..." -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    Write-Host "  OK Ollama API responds. Installed models :" -ForegroundColor Green
    $r.models | ForEach-Object { Write-Host "    - $($_.name)" }
} catch {
    Write-Host "  X Ollama API did NOT respond. Make sure Ollama is running (system tray icon)." -ForegroundColor Red
    Write-Host "    Re-run setup/windows/install.ps1 first."
    exit 1
}

# --- 2. Install Hermes Agent (Nous Research official installer) ---------------

Write-Host "`n[2/9] Installing Hermes Agent (NousResearch)..." -ForegroundColor Yellow
$hermesCmd = Get-Command hermes -ErrorAction SilentlyContinue
if ($hermesCmd) {
    Write-Host "  OK hermes already in PATH : $($hermesCmd.Source)"
    try { & hermes --version } catch { Write-Host "  (hermes --version failed — continuing)" }
} else {
    Write-Host "  Running official installer (Python 3.11, Node, ripgrep, ffmpeg, git)..."
    Write-Host "  This may take several minutes — installer downloads its own deps."
    iex (irm https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1)
    Write-Host "  Installer finished." -ForegroundColor Green
    Write-Host "  IMPORTANT : you may need to RELAUNCH this PowerShell session for 'hermes' to land in PATH." -ForegroundColor Yellow
    Write-Host "  Then re-run this script — it'll skip step [2] and continue from [3]."
    $cont = Read-Host "  Continue anyway in this same session? (y/exit)"
    if ($cont -ne 'y') { exit 0 }
}

# --- 3. Run `hermes setup` (model providers, OAuth, etc.) ---------------------

Write-Host "`n[3/9] Hermes setup wizard..." -ForegroundColor Yellow
Write-Host "  When it asks about a local model provider, use :"
Write-Host "    Provider type  : ollama" -ForegroundColor Cyan
Write-Host "    Base URL       : http://localhost:11434" -ForegroundColor Cyan
Write-Host "    Default model  : gemma4:e4b   (or whatever 'ollama list' shows)" -ForegroundColor Cyan
$runSetup = Read-Host "  Run 'hermes setup' now? (y/skip)"
if ($runSetup -eq 'y') {
    if (Get-Command hermes -ErrorAction SilentlyContinue) {
        try {
            & hermes setup
        } catch {
            Write-Host "  hermes setup exited with an error — note it down and rerun manually." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  hermes not on PATH yet. Open a new PowerShell window and run 'hermes setup' manually." -ForegroundColor Red
    }
} else {
    Write-Host "  Skipped. Run 'hermes setup' yourself later."
}

# --- 4. Initialize Hermes skills directory (one-shot launch) ------------------

Write-Host "`n[4/9] Initializing skills directory..." -ForegroundColor Yellow
$skillsDir = Join-Path $env:USERPROFILE ".hermes\skills"
if (Test-Path $skillsDir) {
    Write-Host "  OK skills directory exists : $skillsDir"
    $existingSkills = Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue
    if ($existingSkills) {
        Write-Host "  Bundled / installed skills :"
        $existingSkills | ForEach-Object { Write-Host "    - $($_.Name)" }
    } else {
        Write-Host "  (directory is empty — skills get created on-demand as you use Hermes)"
    }
} else {
    Write-Host "  Skills directory not yet created. Launch Hermes once (then Ctrl-C exit) :"
    Write-Host "    hermes"
    Write-Host "  This initializes ~/.hermes/, including the skills subfolder."
    Write-Host "  (Doing this in a separate window keeps this script flow clean.)"
}

Write-Host ""
Write-Host "  Notes on Hermes skills :" -ForegroundColor Cyan
Write-Host "    - Bundled skills ship with Hermes itself ; no extra install needed."
Write-Host "    - Hermes also CREATES NEW SKILLS AUTONOMOUSLY after complex tasks"
Write-Host "      (procedural memory — they appear under ~/.hermes/skills/ over time)."
Write-Host "    - Community skills : browse the marketplace at https://agentskills.io"
Write-Host "      and import via the /skills command inside Hermes chat."
Write-Host "    - There is NO documented 'hermes skill install --all' one-liner as of v0.14.0."
Write-Host "      Install the ones you actually need ; don't bulk-grab everything."

# --- 5. Node.js 22 check (Mission Control requirement) ------------------------

Write-Host "`n[5/9] Checking Node.js 22+ (Mission Control needs it)..." -ForegroundColor Yellow
$nodeOk = $false
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVersion = (& node --version) -replace '^v', ''
    $nodeMajor = [int]($nodeVersion.Split('.')[0])
    if ($nodeMajor -ge 22) {
        Write-Host "  OK node v$nodeVersion — good."
        $nodeOk = $true
    } else {
        Write-Host "  WARN node v$nodeVersion — too old. Need 22+."
    }
}
if (-not $nodeOk) {
    Write-Host "  Installing Node 22 via winget..."
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        winget install -e --id OpenJS.NodeJS.LTS --silent
        Write-Host "  Node installed. RELAUNCH PowerShell so 'node' is on PATH, then re-run this script." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "  winget not available. Download Node 22 from https://nodejs.org/en/download (LTS)." -ForegroundColor Red
        Write-Host "  Then re-run this script."
        exit 1
    }
}

# --- 6. Install pnpm ----------------------------------------------------------

Write-Host "`n[6/9] Installing pnpm..." -ForegroundColor Yellow
$pnpmCmd = Get-Command pnpm -ErrorAction SilentlyContinue
if ($pnpmCmd) {
    Write-Host "  OK pnpm already installed : $(& pnpm --version)"
} else {
    if (Get-Command corepack -ErrorAction SilentlyContinue) {
        corepack enable
        corepack prepare pnpm@latest --activate
    } else {
        npm install -g pnpm
    }
    Write-Host "  OK pnpm installed."
}

# --- 7. Clone + install Mission Control ---------------------------------------

Write-Host "`n[7/9] Cloning + installing Mission Control..." -ForegroundColor Yellow
$mcDir = Join-Path $env:USERPROFILE "mission-control"
if (Test-Path (Join-Path $mcDir ".git")) {
    Write-Host "  OK $mcDir already cloned. Pulling latest..."
    Push-Location $mcDir
    try { & git pull --ff-only } catch { Write-Host "  git pull failed — resolve manually." -ForegroundColor Yellow }
    Pop-Location
} else {
    git clone https://github.com/builderz-labs/mission-control.git $mcDir
}

Push-Location $mcDir
$mcInstall = Join-Path $mcDir "install.ps1"
if (Test-Path $mcInstall) {
    Write-Host "  Running Mission Control's install.ps1 -Mode local..."
    & $mcInstall -Mode local
} else {
    Write-Host "  install.ps1 not found in repo — falling back to manual install."
    pnpm install
}
Pop-Location

# --- 8. Firewall (optional) ---------------------------------------------------

Write-Host "`n[8/9] Windows Firewall for Mission Control port 3000..." -ForegroundColor Yellow
Write-Host "  Mission Control listens on localhost:3000 — usually no firewall rule needed"
Write-Host "  if you only access it from the HP itself. If you want to reach it from your"
Write-Host "  Mac via Tailscale, you'll need to open port 3000 (Private profile)."
$openFw = Read-Host "  Open port 3000 in Windows Firewall (Private profile) for Tailscale access? (y/n)"
if ($openFw -eq 'y') {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($isAdmin) {
        try {
            New-NetFirewallRule -Name 'MissionControl-Tailscale' `
                -DisplayName 'Mission Control (Tailscale mesh)' `
                -Direction Inbound -Protocol TCP -LocalPort 3000 `
                -Action Allow -Profile Private | Out-Null
            Write-Host "  OK Firewall rule added." -ForegroundColor Green
        } catch {
            Write-Host "  Firewall rule add failed : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Needs Administrator. Run this in an elevated PowerShell :" -ForegroundColor Yellow
        Write-Host "    New-NetFirewallRule -Name 'MissionControl-Tailscale' -DisplayName 'Mission Control (Tailscale mesh)' -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -Profile Private"
    }
}

# --- 9. Launch instructions ---------------------------------------------------

Write-Host "`n[9/9] Done. To launch the stack :" -ForegroundColor Yellow
@"

  PowerShell window 1 (Hermes — agent loop) :
    hermes

  PowerShell window 2 (Mission Control — web dashboard) :
    cd `$env:USERPROFILE\mission-control
    pnpm dev

  Then open in your browser :
    http://localhost:3000/setup
  Create your admin account on first visit.

  Wiring Mission Control to Hermes :
    1. In Mission Control settings, copy the API key shown after first login.
    2. Register Hermes as an agent via Mission Control's adapter
       (CrewAI / LangGraph / generic REST — see install-hermes-windows.md).
    3. Hermes should appear in the agent list within ~30 seconds.

  Skills :
    Inside Hermes chat, type :
      /skills           → browse loaded skills
      /skill add <id>   → install one from agentskills.io
    Hermes auto-creates new skills as it handles complex tasks.

  Log any issue in docs\TROUBLESHOOTING.md.

"@ | Write-Host

Write-Host "=== Install script done. Read output above for any errors. ===" -ForegroundColor Cyan
