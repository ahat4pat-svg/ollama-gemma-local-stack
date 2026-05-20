function New-KitReportPath {
    param(
        [string]$Prefix = 'report',
        [string]$Directory
    )

    if (-not $Directory) {
        $Directory = Get-KitReportsDirectory
    }

    Initialize-KitDirectory -Path $Directory | Out-Null
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    return Join-Path $Directory "$Prefix-$timestamp.md"
}

function Save-KitMarkdownReport {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Lines
    )

    $directory = Split-Path -Path $Path -Parent
    if ($directory) {
        Initialize-KitDirectory -Path $directory | Out-Null
    }

    Set-Content -Path $Path -Value ($Lines -join [Environment]::NewLine)
    Write-KitInfo "Report saved to $Path"
}
