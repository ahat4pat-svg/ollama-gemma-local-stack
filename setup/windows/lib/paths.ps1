function Get-KitRepositoryRoot {
    $rootPath = Join-Path $PSScriptRoot '..\..\..'
    return (Resolve-Path -Path $rootPath).Path
}

function Initialize-KitDirectory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }

    return $Path
}

function Get-KitReportsDirectory {
    return Join-Path (Get-KitRepositoryRoot) 'reports'
}

function Get-KitBenchmarksResultsDirectory {
    return Join-Path (Get-KitRepositoryRoot) 'benchmarks\results'
}

function Resolve-KitDriveRoot {
    param([Parameter(Mandatory)][string]$Drive)

    $normalized = $Drive.Trim()
    if ($normalized.Length -eq 1) {
        $normalized = "${normalized}:"
    }

    if ($normalized -notmatch '^[A-Za-z]:\\?$') {
        throw "ExternalDrive must look like E: or E:\. Received: $Drive"
    }

    if ($normalized.Length -eq 2) {
        $normalized = '{0}\' -f $normalized
    }

    return $normalized
}

function Get-KitExternalDriveLayout {
    param([Parameter(Mandatory)][string]$Drive)

    $driveRoot = Resolve-KitDriveRoot -Drive $Drive
    $base = Join-Path $driveRoot 'gemma4-local-ai-server-kit'

    return [ordered]@{
        Base      = $base
        Models    = Join-Path $base 'ollama-models'
        Workspace = Join-Path $base 'workspace'
        Datasets  = Join-Path $base 'datasets'
        Reports   = Join-Path $base 'reports'
        Exports   = Join-Path $base 'exports'
        Backups   = Join-Path $base 'backups'
        CloudSync = Join-Path $base 'cloud-sync'
    }
}
