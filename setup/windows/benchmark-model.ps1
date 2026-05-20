param(
    [string]$Model = 'gemma4:26b',
    [string]$Prompt = 'In three bullet points, explain why external-drive-first storage helps a 16 GB Windows local AI server.',
    [string]$ReportPath,
    [switch]$SkipPrompts
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\paths.ps1')
. (Join-Path $PSScriptRoot 'lib\env.ps1')
. (Join-Path $PSScriptRoot 'lib\report.ps1')

Write-KitBanner -Subtitle 'Benchmark mode'

if (-not $ReportPath) {
    $ReportPath = New-KitReportPath -Prefix 'benchmark' -Directory (Get-KitBenchmarksResultsDirectory)
}

$lines = @(
    "# $(Get-KitProductName) benchmark report",
    '',
    "- Time: $(Get-KitTimestamp)",
    "- Model: $Model"
)

if (-not (Test-KitIsWindows)) {
    Write-KitWarning 'Benchmark mode is intended for Windows. This environment can only validate script structure.'
    $lines += ''
    $lines += 'No benchmark was executed because the current environment is not Windows.'
    Save-KitMarkdownReport -Path $ReportPath -Lines $lines
    return
}

if (Test-KitExperimentalModel -Model $Model) {
    Write-KitWarning 'Benchmarking an experimental model choice for a 16 GB machine.'
}

$ollamaPath = Get-KitCommandPath -Name 'ollama'
if (-not $ollamaPath) {
    throw 'ollama was not found in PATH. Run install mode first.'
}

$modelsRoot = [System.Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')
if (-not $modelsRoot) {
    $modelsRoot = Join-Path $env:USERPROFILE '.ollama\models'
}

$driveRoot = [System.IO.Path]::GetPathRoot($modelsRoot)
$driveName = if ($driveRoot) { $driveRoot.TrimEnd('\').TrimEnd(':') } else { 'C' }
$driveInfoBefore = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
$freeBeforeGb = if ($driveInfoBefore) { [Math]::Round($driveInfoBefore.Free / 1GB, 2) } else { $null }

$tags = Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -TimeoutSec 10
$availableModels = @($tags.models | ForEach-Object { $_.name })
$pullSeconds = $null

if ($availableModels -notcontains $Model) {
    if (Confirm-KitAction -Message "Model $Model is not installed. Pull it now for benchmarking?" -SkipPrompts:$SkipPrompts) {
        $pullTimer = Measure-Command { & ollama pull $Model }
        $pullSeconds = [Math]::Round($pullTimer.TotalSeconds, 2)
    } else {
        throw "Model $Model must be installed to benchmark it."
    }
}

$body = @{ model = $Model; prompt = $Prompt; stream = $false } | ConvertTo-Json
$generationText = $null
$generationTimer = Measure-Command {
    $response = Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 300
    $script:generationText = $response.response
}
$generationSeconds = [Math]::Round($generationTimer.TotalSeconds, 2)

$driveInfoAfter = Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue
$freeAfterGb = if ($driveInfoAfter) { [Math]::Round($driveInfoAfter.Free / 1GB, 2) } else { $null }

$lines += ''
$lines += '## Environment'
$lines += "- Ollama binary: $ollamaPath"
$lines += "- Model store: $modelsRoot"
$lines += "- OLLAMA_FLASH_ATTENTION: $([System.Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'User'))"
$lines += "- OLLAMA_KV_CACHE_TYPE: $([System.Environment]::GetEnvironmentVariable('OLLAMA_KV_CACHE_TYPE', 'User'))"
$lines += '- TurboQuant note: document only as an optimization topic unless you have verified runtime support on this exact setup.'

$lines += ''
$lines += '## Measurements'
if ($pullSeconds -ne $null) {
    $lines += "- Pull time: $pullSeconds seconds"
}
$lines += "- Generation time: $generationSeconds seconds"
if ($freeBeforeGb -ne $null) {
    $lines += "- Free space before: $freeBeforeGb GB"
}
if ($freeAfterGb -ne $null) {
    $lines += "- Free space after: $freeAfterGb GB"
}
$lines += "- Prompt: $Prompt"
$lines += "- Response: $generationText"

Save-KitMarkdownReport -Path $ReportPath -Lines $lines
Write-KitSuccess 'Benchmark mode complete.'
