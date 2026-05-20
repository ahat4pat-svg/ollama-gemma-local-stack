function Get-KitDefaultModel {
    return 'gemma4:e4b'
}

function Test-KitExperimentalModel {
    param([Parameter(Mandatory)][string]$Model)
    return $Model -eq 'gemma4:26b'
}

function Get-KitManagedEnvironmentNames {
    return @(
        'OLLAMA_HOST',
        'OLLAMA_MODELS',
        'OLLAMA_MAX_LOADED_MODELS',
        'OLLAMA_NUM_PARALLEL',
        'OLLAMA_FLASH_ATTENTION',
        'OLLAMA_KV_CACHE_TYPE'
    )
}

function Get-KitRecommendedEnvironment {
    param(
        [string]$ModelsPath,
        [switch]$EnableExperimentalOptimizations
    )

    $values = [ordered]@{
        OLLAMA_HOST              = '0.0.0.0:11434'
        OLLAMA_MAX_LOADED_MODELS = '1'
        OLLAMA_NUM_PARALLEL      = '1'
    }

    if ($ModelsPath) {
        $values['OLLAMA_MODELS'] = $ModelsPath
    }

    if ($EnableExperimentalOptimizations) {
        $values['OLLAMA_FLASH_ATTENTION'] = '1'
        $values['OLLAMA_KV_CACHE_TYPE'] = 'q8_0'
    }

    return $values
}

function Set-KitUserEnvironmentVariables {
    param([Parameter(Mandatory)][hashtable]$Values)

    foreach ($name in $Values.Keys) {
        [System.Environment]::SetEnvironmentVariable($name, $Values[$name], 'User')
        Set-Item -Path "Env:$name" -Value $Values[$name]
    }
}

function Remove-KitEnvironmentVariables {
    param([Parameter(Mandatory)][string[]]$Names)

    foreach ($name in $Names) {
        [System.Environment]::SetEnvironmentVariable($name, $null, 'User')
        Remove-Item -Path "Env:$name" -ErrorAction SilentlyContinue
    }
}
