param(
    [string]$Model = 'gemma4:e4b',
    [string]$ExternalDrive,
    [ValidateSet('None', 'iCloud', 'GoogleDrive', 'OneDrive')]
    [string]$CloudProvider = 'None',
    [string]$ReportPath,
    [switch]$SkipPrompts,
    [switch]$EnableExperimentalOptimizations,
    [switch]$EnableFirewallRule
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\paths.ps1')
. (Join-Path $PSScriptRoot 'lib\env.ps1')
. (Join-Path $PSScriptRoot 'lib\report.ps1')

Write-KitBanner -Subtitle 'Install mode'
Write-KitInfo 'Default target for 16 GB machines: gemma4:e4b'
Write-KitInfo 'Experimental benchmark target: gemma4:26b'

if (-not $ReportPath) {
    $ReportPath = New-KitReportPath -Prefix 'install'
}

$lines = @(
    "# $(Get-KitProductName) install report",
    '',
    "- Time: $(Get-KitTimestamp)",
    "- Model: $Model",
    "- External drive: $ExternalDrive",
    "- Experimental env vars enabled: $EnableExperimentalOptimizations"
)

if (-not (Test-KitIsWindows)) {
    Write-KitWarning 'Install mode is intended for Windows. This environment can only validate script structure.'
    $lines += ''
    $lines += 'No installation actions were executed because the current environment is not Windows.'
    Save-KitMarkdownReport -Path $ReportPath -Lines $lines
    return
}

if (Test-KitExperimentalModel -Model $Model) {
    Write-KitWarning 'You selected gemma4:26b. Treat this as an experimental benchmark/test path on a 16 GB machine.'
}

$modelsPath = [System.Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')
if ($ExternalDrive) {
    & (Join-Path $PSScriptRoot 'setup-external-drive.ps1') `
        -ExternalDrive $ExternalDrive `
        -CloudProvider $CloudProvider `
        -SkipPrompts:$SkipPrompts

    $modelsPath = (Get-KitExternalDriveLayout -Drive $ExternalDrive).Models
}

$envValues = Get-KitRecommendedEnvironment -ModelsPath $modelsPath -EnableExperimentalOptimizations:$EnableExperimentalOptimizations
Set-KitUserEnvironmentVariables -Values $envValues

$lines += ''
$lines += '## Environment variables applied'
foreach ($name in $envValues.Keys) {
    $lines += "- $name = $($envValues[$name])"
}

if ($EnableExperimentalOptimizations) {
    Write-KitWarning 'Optional KV-cache / Flash Attention env vars were enabled. Verify support on your installed Ollama version.'
} else {
    Write-KitInfo 'Leaving optional KV-cache / Flash Attention env vars disabled unless explicitly requested.'
}

$ollamaPath = Get-KitCommandPath -Name 'ollama'
if (-not $ollamaPath) {
    $installerPath = Join-Path $env:TEMP 'OllamaSetup.exe'
    Write-KitWarning 'Ollama was not found. Downloading the official Windows installer.'
    Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile $installerPath
    Start-Process -FilePath $installerPath -Wait
    $lines += ''
    $lines += '## Ollama installer'
    $lines += "- Downloaded to: $installerPath"
    $lines += '- Relaunch PowerShell and run Install mode again after the installer finishes if ollama is still not in PATH.'
    Save-KitMarkdownReport -Path $ReportPath -Lines $lines
    Write-KitWarning 'Installer completed. Re-run this command if ollama is not yet available in PATH.'
    return
}

Write-KitSuccess "Ollama detected at $ollamaPath"
$version = (& ollama --version | Out-String).Trim()
Write-KitInfo $version

Write-KitInfo 'If Ollama is already running in the system tray, quit and relaunch it now so updated environment variables take effect.'
if (-not $SkipPrompts) {
    [void](Read-Host 'Press ENTER after Ollama has been relaunched')
}

try {
    Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 10 | Out-Null
    Write-KitSuccess 'Ollama API responded on localhost.'
} catch {
    Write-KitWarning 'The Ollama API did not respond yet. The pull step may still work if the tray app is starting.'
}

Write-KitInfo "Pulling model $Model ..."
& ollama pull $Model

$sampleResponse = $null
try {
    $body = @{ model = $Model; prompt = 'Reply with one short sentence confirming the local AI server kit is installed.'; stream = $false } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 180
    $sampleResponse = $response.response
    Write-KitSuccess 'Local generation smoke test succeeded.'
} catch {
    Write-KitWarning 'Model pull completed, but the local smoke prompt did not return. Run Test mode next.'
}

if ($EnableFirewallRule) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($isAdmin) {
        New-NetFirewallRule -Name 'Ollama-Tailscale' -DisplayName 'Ollama (Tailscale mesh)' -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow -Profile Private -ErrorAction SilentlyContinue | Out-Null
        Write-KitSuccess 'Firewall rule ensured for TCP 11434 on Private profile.'
    } else {
        Write-KitWarning 'EnableFirewallRule was requested, but this session is not elevated. Run the firewall command from an Administrator PowerShell if needed.'
    }
}

$lines += ''
$lines += '## Ollama'
$lines += "- Binary: $ollamaPath"
$lines += "- Version: $version"
$lines += "- Model pulled: $Model"
if ($sampleResponse) {
    $lines += "- Smoke response: $sampleResponse"
}
$lines += '- Tailscale note: keep Tailscale installed if this machine will serve other devices on the tailnet.'
$lines += '- Next step: run .\setup\windows\bootstrap.ps1 -Mode Test -Model ' + $Model

Save-KitMarkdownReport -Path $ReportPath -Lines $lines
Write-KitSuccess 'Install mode complete.'
