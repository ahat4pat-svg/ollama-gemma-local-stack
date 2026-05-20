param(
    [switch]$RemoveModels,
    [switch]$RunUninstaller,
    [string]$ReportPath,
    [switch]$SkipPrompts
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\paths.ps1')
. (Join-Path $PSScriptRoot 'lib\env.ps1')
. (Join-Path $PSScriptRoot 'lib\report.ps1')

Write-KitBanner -Subtitle 'Ollama cleanup/reset'
Write-KitWarning 'This reset keeps Tailscale and other non-Ollama system components in place.'

if (-not (Test-KitIsWindows)) {
    Write-KitWarning 'Cleanup is intended for Windows. No changes were made.'
    return
}

if (-not (Confirm-KitAction -Message 'Stop Ollama and remove the selected local Ollama state?' -SkipPrompts:$SkipPrompts -DefaultNo)) {
    Write-KitInfo 'Cleanup cancelled by user.'
    return
}

$stoppedProcesses = @()
foreach ($processName in @('ollama app', 'ollama')) {
    Get-Process -Name $processName -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        $stoppedProcesses += $_.ProcessName
    }
}

$targets = @(
    (Join-Path $env:LOCALAPPDATA 'Ollama'),
    (Join-Path $env:APPDATA 'Ollama')
)

$defaultModelPath = Join-Path $env:USERPROFILE '.ollama'
$customModelsPath = [System.Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')

if ($RemoveModels) {
    $targets += $defaultModelPath
    if ($customModelsPath -and $customModelsPath -ne $defaultModelPath) {
        $targets += $customModelsPath
    }
}

$removedPaths = @()
$totalBytesRemoved = [int64]0
foreach ($target in ($targets | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $target) {
        $totalBytesRemoved += Get-KitDirectorySizeBytes -Path $target
        Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
        $removedPaths += $target
    }
}

Remove-KitEnvironmentVariables -Names (Get-KitManagedEnvironmentNames)

$uninstallCommand = $null
if ($RunUninstaller) {
    $uninstallEntries = @(
        Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue,
        Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue,
        Get-ItemProperty 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue
    ) | Where-Object { $_.DisplayName -match 'Ollama' -and $_.UninstallString }

    $entry = $uninstallEntries | Select-Object -First 1
    if ($entry) {
        $uninstallCommand = $entry.UninstallString
        if (Confirm-KitAction -Message 'Launch the registered Ollama uninstaller now?' -SkipPrompts:$SkipPrompts -DefaultNo) {
            Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $entry.UninstallString -Wait
        }
    }
}

if (-not $ReportPath) {
    $ReportPath = New-KitReportPath -Prefix 'ollama-clean'
}

$lines = @(
    "# $(Get-KitProductName) Ollama cleanup",
    '',
    "- Time: $(Get-KitTimestamp)",
    "- Remove models: $RemoveModels",
    "- Run uninstaller requested: $RunUninstaller",
    "- Tailscale preserved: yes",
    "- Approximate bytes removed: $(Format-KitBytes -Bytes $totalBytesRemoved)",
    '',
    '## Stopped processes'
)

if ($stoppedProcesses.Count -eq 0) {
    $lines += '- No running Ollama processes were found.'
} else {
    foreach ($name in $stoppedProcesses | Select-Object -Unique) {
        $lines += "- $name"
    }
}

$lines += ''
$lines += '## Removed paths'
if ($removedPaths.Count -eq 0) {
    $lines += '- No targeted Ollama paths were present.'
} else {
    foreach ($path in $removedPaths) {
        $lines += "- $path"
    }
}

$lines += ''
$lines += '## Environment variables cleared'
foreach ($name in Get-KitManagedEnvironmentNames) {
    $lines += "- $name"
}

if ($uninstallCommand) {
    $lines += ''
    $lines += '## Registered uninstall command'
    $lines += "- $uninstallCommand"
}

Save-KitMarkdownReport -Path $ReportPath -Lines $lines
Write-KitSuccess 'Ollama cleanup/reset complete.'
