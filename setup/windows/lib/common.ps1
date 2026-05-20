$script:KitProductName = 'Gemma 4 on 16 GB — Local AI Server Kit'

function Get-KitProductName {
    return $script:KitProductName
}

function Get-KitTimestamp {
    return Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

function Write-KitBanner {
    param(
        [string]$Subtitle
    )

    Write-Host ''
    Write-Host "=== $(Get-KitProductName) ===" -ForegroundColor Cyan
    if ($Subtitle) {
        Write-Host $Subtitle -ForegroundColor DarkCyan
    }
    Write-Host ''
}

function Write-KitInfo {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Gray
}

function Write-KitWarning {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-KitSuccess {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Confirm-KitAction {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [switch]$SkipPrompts,
        [switch]$DefaultNo
    )

    if ($SkipPrompts) {
        return -not $DefaultNo
    }

    $suffix = if ($DefaultNo) { 'y/N' } else { 'Y/n' }
    $response = Read-Host "$Message ($suffix)"

    if ([string]::IsNullOrWhiteSpace($response)) {
        return -not $DefaultNo
    }

    return $response -match '^(y|yes)$'
}

function Test-KitIsWindows {
    return [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
}

function Get-KitCommandPath {
    param([Parameter(Mandatory)][string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    return $null
}

function Format-KitBytes {
    param([double]$Bytes)

    if ($Bytes -ge 1TB) { return '{0:N2} TB' -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N2} MB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N2} KB' -f ($Bytes / 1KB) }

    return '{0:N0} B' -f $Bytes
}

function Get-KitDirectorySizeBytes {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [int64]0
    }

    $measure = Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum

    return [int64]($measure.Sum)
}
