param(
    [string]$Model = 'gemma4:e4b',
    [string]$ExternalDrive,
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\paths.ps1')
. (Join-Path $PSScriptRoot 'lib\env.ps1')
. (Join-Path $PSScriptRoot 'lib\report.ps1')

Write-KitBanner -Subtitle 'Audit mode'

if (-not $ReportPath) {
    $ReportPath = New-KitReportPath -Prefix 'audit'
}

$lines = @(
    "# $(Get-KitProductName) audit report",
    '',
    "- Time: $(Get-KitTimestamp)",
    "- Requested model: $Model",
    "- External drive argument: $ExternalDrive"
)

if (-not (Test-KitIsWindows)) {
    Write-KitWarning 'Audit mode is intended for Windows. This environment can only validate script structure.'
    $lines += ''
    $lines += 'This report was generated from a non-Windows environment, so no Windows audit data was collected.'
    Save-KitMarkdownReport -Path $ReportPath -Lines $lines
    return
}

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$freeRamGb = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
$totalRamGb = [Math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
$drives = Get-PSDrive -PSProvider FileSystem | Sort-Object Name
$externalCandidates = @()
try {
    $externalCandidates = Get-CimInstance Win32_LogicalDisk |
        Where-Object { $_.DeviceID -ne 'C:' -and $_.DriveType -in 2, 3 } |
        Sort-Object DeviceID
} catch {
    $externalCandidates = @()
}

$ollamaPath = Get-KitCommandPath -Name 'ollama'
$tailscalePath = Get-KitCommandPath -Name 'tailscale'

Write-KitInfo "Windows machine: $($computer.Name)"
Write-KitInfo "RAM free/total: $freeRamGb GB / $totalRamGb GB"
Write-KitInfo "Ollama detected: $([bool]$ollamaPath)"
Write-KitInfo "Tailscale detected: $([bool]$tailscalePath)"

$lines += ''
$lines += '## System summary'
$lines += "- Computer: $($computer.Name)"
$lines += "- Windows: $($os.Caption) $($os.Version)"
$lines += "- RAM free/total: $freeRamGb GB / $totalRamGb GB"
$lines += "- Ollama installed: $([bool]$ollamaPath)"
$lines += "- Tailscale installed: $([bool]$tailscalePath)"

$lines += ''
$lines += '## File-system drives'
foreach ($drive in $drives) {
    $lines += "- $($drive.Name): free $([Math]::Round($drive.Free / 1GB, 2)) GB / used $([Math]::Round($drive.Used / 1GB, 2)) GB"
}

$lines += ''
$lines += '## External-drive candidates'
if ($externalCandidates.Count -eq 0) {
    $lines += '- No non-C: removable/fixed drive candidates detected during audit.'
} else {
    foreach ($candidate in $externalCandidates) {
        $lines += "- $($candidate.DeviceID) — $([Math]::Round($candidate.FreeSpace / 1GB, 2)) GB free / $([Math]::Round($candidate.Size / 1GB, 2)) GB total"
    }
}

$lines += ''
$lines += '## Managed OLLAMA_* environment variables'
foreach ($name in Get-KitManagedEnvironmentNames) {
    $value = [System.Environment]::GetEnvironmentVariable($name, 'User')
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = '(not set)'
    }

    $lines += "- $name = $value"
}

$lines += ''
$lines += '## Recommended next actions'
$lines += "- Start with $(Get-KitDefaultModel) unless you explicitly want an experimental benchmark."
$lines += '- Keep Tailscale installed if the machine should remain reachable from other devices.'
$lines += '- Prefer an external drive for model storage on 16 GB Windows machines.'
$lines += '- Use Prepare mode before reinstalling if the machine already has a messy Ollama state.'

Save-KitMarkdownReport -Path $ReportPath -Lines $lines
Write-KitSuccess 'Audit complete.'
