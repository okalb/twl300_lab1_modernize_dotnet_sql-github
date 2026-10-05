<#
.SYNOPSIS
    Connects the lab Container App to Azure SQL Database and Azure Container Registry.

.DESCRIPTION
    Applies the post-deployment configuration that the lab expects on the
    predeployed Container App (ca-caldova-<suffix>):

    - A secret named inventory-connection-string that holds the Azure SQL
      connection string for the CaldovaInventory database.
    - A registry entry for <registry>.azurecr.io that uses the user-assigned
      managed identity (id-caldova-<suffix>) to pull images.
    - The environment variable ConnectionStrings__Inventory, which references
      the secret.

    The bootstrap image, ingress, scale, and workload profile settings are kept.
    The script sends one explicit update (PUT) with API version 2024-03-01, and
    passes the request body through a temporary file that it deletes when it
    finishes. It never prints the connection string or the password.

    Deploy-LabInfrastructure.ps1 runs this script for you. Run it yourself only if
    you need to reapply the configuration.

.PARAMETER ResourceGroupName
    Name of the lab resource group.

.PARAMETER NameSuffix
    The resource name suffix used by the deployment (5-12 lowercase letters and digits).

.PARAMETER SqlAdministratorPassword
    SecureString password for the Azure SQL administrator (caldovaadmin). If you
    omit it, the script prompts for it.

.PARAMETER SubscriptionId
    Optional subscription ID. Defaults to the current Azure CLI subscription.

.EXAMPLE
    ./scripts/setup/Configure-ContainerApp.ps1 -ResourceGroupName rg-caldova-lab -NameSuffix abcd1234
#>
#Requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9]{5,12}$')]
    [string]$NameSuffix,

    [securestring]$SqlAdministratorPassword,

    [string]$SubscriptionId,

    [ValidateRange(1, 10)]
    [int]$MaxAttempts = 5,

    [ValidateRange(5, 300)]
    [int]$RetryDelaySeconds = 20
)

$ErrorActionPreference = 'Stop'

$apiVersion = '2024-03-01'
$databaseName = 'CaldovaInventory'
$sqlAdministratorLogin = 'caldovaadmin'
$secretName = 'inventory-connection-string'

function Invoke-AzCli {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $output = & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        $shown = $Arguments[0..([Math]::Min(2, $Arguments.Count - 1))] -join ' '
        throw "Azure CLI command failed (exit code $LASTEXITCODE): az $shown"
    }
    return $output
}

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return & $Action
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                throw "$Description failed after $MaxAttempts attempts. $($_.Exception.Message)"
            }
            Write-Warning "$Description failed (attempt $attempt of $MaxAttempts). Retrying in $RetryDelaySeconds seconds."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }
}

function New-PrivateTempFile {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ('caldova-' + [guid]::NewGuid().ToString('N') + '.json')
    [System.IO.File]::WriteAllText($path, '')
    if (-not $IsWindows) {
        try {
            [System.IO.File]::SetUnixFileMode($path, [System.IO.UnixFileMode]'UserRead, UserWrite')
        }
        catch {
            & chmod 600 $path
        }
    }
    return $path
}

$bodyFile = $null
$connectionString = $null

try {
    if ($SubscriptionId) {
        Invoke-AzCli -Arguments @('account', 'set', '--subscription', $SubscriptionId, '--only-show-errors') | Out-Null
    }
    $subscription = Invoke-AzCli -Arguments @('account', 'show', '--query', 'id', '--output', 'tsv')

    if (-not $SqlAdministratorPassword) {
        $SqlAdministratorPassword = Read-Host "Enter the Azure SQL administrator password for '$sqlAdministratorLogin'" -AsSecureString
    }

    $appName = "ca-caldova-$NameSuffix"
    $registryName = "acrcaldova$NameSuffix"
    $identityName = "id-caldova-$NameSuffix"
    $sqlServerName = "sql-caldova-$NameSuffix"
    $appUrl = "https://management.azure.com/subscriptions/$subscription/resourceGroups/$ResourceGroupName/providers/Microsoft.App/containerApps/${appName}?api-version=$apiVersion"

    Write-Host "Configuring Container App '$appName'."

    $app = Invoke-WithRetry -Description "Reading Container App '$appName'" -Action {
        (Invoke-AzCli -Arguments @('rest', '--method', 'get', '--url', $appUrl, '--output', 'json')) -join "`n" | ConvertFrom-Json -Depth 100
    }

    $identityId = Invoke-WithRetry -Description "Reading managed identity '$identityName'" -Action {
        Invoke-AzCli -Arguments @('identity', 'show', '--name', $identityName, '--resource-group', $ResourceGroupName, '--query', 'id', '--output', 'tsv')
    }

    $sqlServerFqdn = Invoke-WithRetry -Description "Reading SQL server '$sqlServerName'" -Action {
        Invoke-AzCli -Arguments @('sql', 'server', 'show', '--name', $sqlServerName, '--resource-group', $ResourceGroupName, '--query', 'fullyQualifiedDomainName', '--output', 'tsv')
    }

    if ($null -eq $app -or $null -eq $app.properties) {
        throw "Container App '$appName' was not found."
    }
    if ([string]::IsNullOrWhiteSpace([string]$identityId)) {
        throw "Managed identity '$identityName' was not found."
    }
    if ([string]::IsNullOrWhiteSpace([string]$sqlServerFqdn)) {
        throw "SQL server '$sqlServerName' was not found or has no fully qualified domain name."
    }

    # Use the identity resource ID exactly as the Container App already lists it.
    if ($app.identity -and $app.identity.userAssignedIdentities) {
        $assigned = $app.identity.userAssignedIdentities.PSObject.Properties.Name |
            Where-Object { $_ -ieq $identityId } |
            Select-Object -First 1
        if ($assigned) {
            $identityId = $assigned
        }
    }

    $configuration = $app.properties.configuration
    $template = $app.properties.template
    $container = @($template.containers)[0]
    if ($null -eq $container) {
        throw "Container App '$appName' doesn't contain a container definition."
    }

    # Same settings as the original post-build configuration. The builder quotes values,
    # so a password that contains ; or quotation marks still produces a valid connection string.
    $builder = [System.Data.Common.DbConnectionStringBuilder]::new()
    $builder['Server'] = "tcp:$sqlServerFqdn,1433"
    $builder['Initial Catalog'] = $databaseName
    $builder['User ID'] = $sqlAdministratorLogin
    $builder['Password'] = [System.Net.NetworkCredential]::new('', $SqlAdministratorPassword).Password
    $builder['Encrypt'] = 'True'
    $builder['TrustServerCertificate'] = 'False'
    $builder['Connection Timeout'] = '30'
    $connectionString = $builder.ConnectionString
    $builder.Clear()

    $containerBody = [ordered]@{
        name      = [string]$container.name
        image     = [string]$container.image
        resources = [ordered]@{
            cpu    = $container.resources.cpu
            memory = [string]$container.resources.memory
        }
        env       = @(
            [ordered]@{
                name      = 'ConnectionStrings__Inventory'
                secretRef = $secretName
            }
        )
    }

    $scaleBody = [ordered]@{
        minReplicas = [int]$template.scale.minReplicas
        maxReplicas = [int]$template.scale.maxReplicas
    }

    $ingressBody = [ordered]@{
        external      = [bool]$configuration.ingress.external
        targetPort    = [int]$configuration.ingress.targetPort
        transport     = [string]$configuration.ingress.transport
        allowInsecure = [bool]$configuration.ingress.allowInsecure
    }
    if ($null -ne $configuration.ingress.traffic) {
        $ingressBody.traffic = @(
            $configuration.ingress.traffic | ForEach-Object {
                [ordered]@{
                    weight         = [int]$_.weight
                    latestRevision = [bool]$_.latestRevision
                }
            }
        )
    }

    $propertiesBody = [ordered]@{
        managedEnvironmentId = [string]$app.properties.managedEnvironmentId
        configuration        = [ordered]@{
            activeRevisionsMode = [string]$configuration.activeRevisionsMode
            ingress             = $ingressBody
            secrets             = @(
                [ordered]@{
                    name  = $secretName
                    value = $connectionString
                }
            )
            registries          = @(
                [ordered]@{
                    server   = "$registryName.azurecr.io"
                    identity = $identityId
                }
            )
        }
        template             = [ordered]@{
            containers = @($containerBody)
            scale      = $scaleBody
        }
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$app.properties.workloadProfileName)) {
        $propertiesBody.workloadProfileName = [string]$app.properties.workloadProfileName
    }

    # The managed identity is a top-level Container App property. Sending only the
    # properties object makes Azure reject the registry identity as "not found".
    $identityMap = @{}
    $identityMap[$identityId] = @{}

    $requestBody = [ordered]@{
        location   = [string]$app.location
        identity   = [ordered]@{
            type                   = 'UserAssigned'
            userAssignedIdentities = $identityMap
        }
        properties = $propertiesBody
    }

    $bodyFile = New-PrivateTempFile
    [System.IO.File]::WriteAllText($bodyFile, ($requestBody | ConvertTo-Json -Depth 100))
    $connectionString = $null
    $requestBody = $null

    Invoke-WithRetry -Description "Updating Container App '$appName'" -Action {
        Invoke-AzCli -Arguments @('rest', '--method', 'put', '--url', $appUrl, '--body', "@$bodyFile", '--headers', 'Content-Type=application/json', '--output', 'none', '--only-show-errors') | Out-Null
    } | Out-Null

    # Wait for the update to finish, and then verify the configuration without reading secret values.
    $updated = $null
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $updated = (Invoke-AzCli -Arguments @('rest', '--method', 'get', '--url', $appUrl, '--output', 'json')) -join "`n" | ConvertFrom-Json -Depth 100
        $state = [string]$updated.properties.provisioningState
        if ($state -eq 'Succeeded') {
            break
        }
        if ($state -eq 'Failed') {
            throw "The Container App update failed. Check the Container App in the Azure portal, and then run the script again."
        }
        Start-Sleep -Seconds 10
    }
    if ([string]$updated.properties.provisioningState -ne 'Succeeded') {
        throw "The Container App didn't reach the Succeeded state. Current state: $($updated.properties.provisioningState)."
    }

    $secretNames = @($updated.properties.configuration.secrets | ForEach-Object { $_.name })
    $registryServers = @($updated.properties.configuration.registries | ForEach-Object { $_.server })
    $envNames = @(@($updated.properties.template.containers)[0].env | ForEach-Object { $_.name })

    if ($secretNames -notcontains $secretName) {
        throw "Secret '$secretName' wasn't found on the Container App."
    }
    if ($registryServers -notcontains "$registryName.azurecr.io") {
        throw "Registry '$registryName.azurecr.io' wasn't found on the Container App."
    }
    if ($envNames -notcontains 'ConnectionStrings__Inventory') {
        throw "Environment variable 'ConnectionStrings__Inventory' wasn't found on the Container App."
    }

    Write-Host "Container App '$appName' is configured: secret '$secretName', registry '$registryName.azurecr.io' (managed identity), and ConnectionStrings__Inventory."
}
finally {
    if ($bodyFile) {
        Remove-Item -LiteralPath $bodyFile -Force -ErrorAction SilentlyContinue
    }
    $connectionString = $null
}
