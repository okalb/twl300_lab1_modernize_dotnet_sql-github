<#
.SYNOPSIS
    Registers the Azure resource providers that the Caldova lab template uses.

.DESCRIPTION
    Registers Microsoft.App, Microsoft.OperationalInsights, Microsoft.Sql,
    Microsoft.ContainerRegistry, and Microsoft.ManagedIdentity in the current
    (or specified) subscription, and then waits until each provider reports the
    Registered state.

    Registration applies to the whole subscription. Deleting the lab resource
    group doesn't unregister the providers.

    Run "az login" before you run this script. Deploy-LabInfrastructure.ps1 calls
    this script automatically unless you specify -SkipProviderRegistration.

.PARAMETER SubscriptionId
    Optional subscription ID. Defaults to the current Azure CLI subscription.

.PARAMETER TimeoutSeconds
    Maximum time to wait for all providers to reach the Registered state.

.EXAMPLE
    ./scripts/setup/Register-ResourceProviders.ps1
#>
#Requires -Version 7.2
[CmdletBinding()]
param(
    [string]$SubscriptionId,

    [ValidateRange(60, 3600)]
    [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = 'Stop'

$providers = @(
    'Microsoft.App',
    'Microsoft.OperationalInsights',
    'Microsoft.Sql',
    'Microsoft.ContainerRegistry',
    'Microsoft.ManagedIdentity'
)

$registrationRetryCount = 3
$registrationRetryDelaySeconds = 10
$pollIntervalSeconds = 15

function Invoke-AzCli {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $output = & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        $shown = $Arguments[0..([Math]::Min(2, $Arguments.Count - 1))] -join ' '
        throw "Azure CLI command failed (exit code $LASTEXITCODE): az $shown"
    }
    return $output
}

if ($SubscriptionId) {
    Invoke-AzCli -Arguments @('account', 'set', '--subscription', $SubscriptionId, '--only-show-errors') | Out-Null
}

$subscriptionName = Invoke-AzCli -Arguments @('account', 'show', '--query', 'name', '--output', 'tsv')
Write-Host "Registering resource providers in subscription '$subscriptionName'."

foreach ($provider in $providers) {
    $state = Invoke-AzCli -Arguments @('provider', 'show', '--namespace', $provider, '--query', 'registrationState', '--output', 'tsv')
    if ($state -eq 'Registered') {
        Write-Host "$provider is already registered."
        continue
    }

    for ($attempt = 1; $attempt -le $registrationRetryCount; $attempt++) {
        & az provider register --namespace $provider --only-show-errors | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Started registration for $provider."
            break
        }

        if ($attempt -eq $registrationRetryCount) {
            throw "Could not start registration for $provider after $registrationRetryCount attempts."
        }

        Write-Warning "The registration request for $provider failed. Retrying in $registrationRetryDelaySeconds seconds (attempt $attempt of $registrationRetryCount)."
        Start-Sleep -Seconds $registrationRetryDelaySeconds
    }
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$pending = [System.Collections.Generic.List[string]]::new()
foreach ($provider in $providers) {
    $pending.Add($provider)
}

while ($pending.Count -gt 0) {
    foreach ($provider in @($pending)) {
        $state = Invoke-AzCli -Arguments @('provider', 'show', '--namespace', $provider, '--query', 'registrationState', '--output', 'tsv')
        if ($state -eq 'Registered') {
            Write-Host "$provider is registered."
            [void]$pending.Remove($provider)
        }
    }

    if ($pending.Count -eq 0) {
        break
    }

    if ((Get-Date) -gt $deadline) {
        throw "Timed out after $TimeoutSeconds seconds waiting for: $($pending -join ', '). Check the resource providers for your subscription in the Azure portal, and then run the script again."
    }

    Write-Host "Waiting for registration to finish: $($pending -join ', ')"
    Start-Sleep -Seconds $pollIntervalSeconds
}

Write-Host 'All required resource providers are registered.'
