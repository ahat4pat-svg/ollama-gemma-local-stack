param(
    [Parameter(Mandatory)]
    [string]$ExternalDrive,
    [ValidateSet('None', 'iCloud', 'GoogleDrive', 'OneDrive')]
    [string]$CloudProvider = 'None',
    [string]$ReportPath,
    [switch]$SkipPrompts
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\paths.ps1')
. (Join-Path $PSScriptRoot 'lib\env.ps1')
. (Join-Path $PSScriptRoot 'lib\report.ps1')

Write-KitBanner -Subtitle 'External drive setup'

if (-not (Test-KitIsWindows)) {
    Write-KitWarning 'External drive setup is intended for Windows. No changes were made.'
    return
}

$driveRoot = Resolve-KitDriveRoot -Drive $ExternalDrive
if (-not (Test-Path -LiteralPath $driveRoot)) {
    throw "Drive root not found: $driveRoot"
}

$layout = Get-KitExternalDriveLayout -Drive $ExternalDrive
Write-KitInfo "Preparing external-drive layout under $($layout.Base)"

if (-not (Confirm-KitAction -Message 'Create or reuse the external-drive folder layout and set OLLAMA_MODELS?' -SkipPrompts:$SkipPrompts)) {
    Write-KitWarning 'External drive setup cancelled by user.'
    return
}

foreach ($path in $layout.Values) {
    Initialize-KitDirectory -Path $path | Out-Null
}

if ($CloudProvider -ne 'None') {
    Initialize-KitDirectory -Path (Join-Path $layout.CloudSync $CloudProvider) | Out-Null
}

$envValues = Get-KitRecommendedEnvironment -ModelsPath $layout.Models
Set-KitUserEnvironmentVariables -Values $envValues

if (-not $ReportPath) {
    $ReportPath = New-KitReportPath -Prefix 'external-drive-setup'
}

$lines = @(
    "# $(Get-KitProductName) external drive setup",
    '',
    "- Time: $(Get-KitTimestamp)",
    "- Drive: $driveRoot",
    "- Cloud provider: $CloudProvider",
    '',
    '## Created or confirmed paths'
)

foreach ($entry in $layout.GetEnumerator()) {
    $lines += "- $($entry.Key): $($entry.Value)"
}

$lines += ''
$lines += '## Environment changes'
$lines += "- OLLAMA_MODELS = $($layout.Models)"
$lines += '- OLLAMA_HOST = 0.0.0.0:11434'
$lines += '- OLLAMA_MAX_LOADED_MODELS = 1'
$lines += '- OLLAMA_NUM_PARALLEL = 1'

Save-KitMarkdownReport -Path $ReportPath -Lines $lines
Write-KitSuccess "External-drive setup complete. Models will be stored at $($layout.Models)"
