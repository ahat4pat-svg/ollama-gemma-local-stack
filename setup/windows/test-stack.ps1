param(
    [string]$Model = 'gemma4:e4b',
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\paths.ps1')
. (Join-Path $PSScriptRoot 'lib\env.ps1')
. (Join-Path $PSScriptRoot 'lib\report.ps1')

Write-KitBanner -Subtitle 'Test mode'

if (-not $ReportPath) {
    $ReportPath = New-KitReportPath -Prefix 'test'
}

$lines = @(
    "# $(Get-KitProductName) test report",
    '',
    "- Time: $(Get-KitTimestamp)",
    "- Model: $Model"
)

if (-not (Test-KitIsWindows)) {
    Write-KitWarning 'Test mode is intended for Windows. This environment can only validate script structure.'
    $lines += ''
    $lines += 'No Windows runtime checks were executed in this environment.'
    Save-KitMarkdownReport -Path $ReportPath -Lines $lines
    return
}

$ollamaPath = Get-KitCommandPath -Name 'ollama'
if (-not $ollamaPath) {
    throw 'ollama was not found in PATH. Run install mode first.'
}

$version = (& ollama --version | Out-String).Trim()
Write-KitInfo $version

$tags = Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 10
$availableModels = @($tags.models | ForEach-Object { $_.name })
$modelInstalled = $availableModels -contains $Model

$generationText = $null
$generationSeconds = $null
if ($modelInstalled) {
    $body = @{ model = $Model; prompt = 'Reply with one short line confirming the local AI server kit is running.'; stream = $false } | ConvertTo-Json
    $timer = Measure-Command {
        $response = Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 120
        $script:generationText = $response.response
    }
    $generationSeconds = [Math]::Round($timer.TotalSeconds, 2)
    Write-KitSuccess "Generation test succeeded in $generationSeconds seconds."
} else {
    Write-KitWarning "Model $Model is not currently installed."
}

$tailscalePath = Get-KitCommandPath -Name 'tailscale'
$tailscaleLines = @()
if ($tailscalePath) {
    try {
        $tailscaleLines = @(& tailscale status 2>$null | Select-Object -First 5)
    } catch {
        $tailscaleLines = @('tailscale status could not be collected.')
    }
}

$lines += ''
$lines += '## Ollama'
$lines += "- Binary: $ollamaPath"
$lines += "- Version: $version"
$lines += '- API tags endpoint reachable: yes'
$lines += "- Requested model installed: $modelInstalled"

if ($generationSeconds -ne $null) {
    $lines += "- Generation time: $generationSeconds seconds"
    $lines += "- Sample response: $generationText"
}

$lines += ''
$lines += '## Tailscale'
if ($tailscalePath) {
    $lines += "- Binary: $tailscalePath"
    foreach ($line in $tailscaleLines) {
        if ($line) {
            $lines += "- $line"
        }
    }
} else {
    $lines += '- Tailscale CLI not detected in PATH.'
}

Save-KitMarkdownReport -Path $ReportPath -Lines $lines
Write-KitSuccess 'Test mode complete.'
