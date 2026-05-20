param(
    [ValidateSet('Audit', 'Prepare', 'Install', 'Benchmark', 'Test')]
    [string]$Mode = 'Audit',
    [string]$Model = 'gemma4:e4b',
    [string]$ExternalDrive,
    [ValidateSet('Safe', 'Aggressive')]
    [string]$Profile = 'Safe',
    [ValidateSet('None', 'iCloud', 'GoogleDrive', 'OneDrive')]
    [string]$CloudProvider = 'None',
    [string]$ReportPath,
    [switch]$SkipPrompts,
    [switch]$RemoveExistingModels,
    [switch]$EnableExperimentalOptimizations,
    [switch]$EnableFirewallRule
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\paths.ps1')
. (Join-Path $PSScriptRoot 'lib\env.ps1')
. (Join-Path $PSScriptRoot 'lib\report.ps1')

Write-KitBanner -Subtitle "Bootstrap mode: $Mode"
Write-KitInfo "Profile: $Profile"
Write-KitInfo "Model: $Model"

switch ($Mode) {
    'Audit' {
        & (Join-Path $PSScriptRoot 'audit.ps1') -Model $Model -ExternalDrive $ExternalDrive -ReportPath $ReportPath
    }

    'Prepare' {
        & (Join-Path $PSScriptRoot 'audit.ps1') -Model $Model -ExternalDrive $ExternalDrive -ReportPath $ReportPath

        if ($ExternalDrive) {
            & (Join-Path $PSScriptRoot 'setup-external-drive.ps1') `
                -ExternalDrive $ExternalDrive `
                -CloudProvider $CloudProvider `
                -SkipPrompts:$SkipPrompts
        } else {
            Write-KitWarning 'No external drive was provided. Prepare mode can still audit and clean, but external-drive-first storage is recommended.'
        }

        if (Confirm-KitAction -Message 'Run Ollama cleanup/reset now?' -SkipPrompts:$SkipPrompts -DefaultNo) {
            & (Join-Path $PSScriptRoot 'clean-ollama.ps1') `
                -RemoveModels:$RemoveExistingModels `
                -SkipPrompts:$SkipPrompts
        } else {
            Write-KitInfo 'Skipped Ollama cleanup/reset.'
        }

        Write-KitSuccess "Prepare mode complete. Next: .\setup\windows\bootstrap.ps1 -Mode Install -Model $Model"
    }

    'Install' {
        & (Join-Path $PSScriptRoot 'install.ps1') `
            -Model $Model `
            -ExternalDrive $ExternalDrive `
            -CloudProvider $CloudProvider `
            -ReportPath $ReportPath `
            -SkipPrompts:$SkipPrompts `
            -EnableExperimentalOptimizations:$EnableExperimentalOptimizations `
            -EnableFirewallRule:$EnableFirewallRule
    }

    'Benchmark' {
        & (Join-Path $PSScriptRoot 'benchmark-model.ps1') `
            -Model $Model `
            -ReportPath $ReportPath `
            -SkipPrompts:$SkipPrompts
    }

    'Test' {
        & (Join-Path $PSScriptRoot 'test-stack.ps1') `
            -Model $Model `
            -ReportPath $ReportPath
    }
}
