<#
.SYNOPSIS
    Predeploys the Azure infrastructure for the Caldova modernization lab.

.DESCRIPTION
    The script:

    1. Confirms that Azure CLI is signed in and selects the subscription.
    2. Validates the region and registers the required resource providers.
    3. Creates the lab resource group, or reuses it if it already exists.
    4. Generates a resource name suffix (or reuses the suffix from an earlier run)
       and checks that the container registry and SQL server names are available.
    5. Prompts securely for the Azure SQL administrator password and checks it
       against the Azure SQL password rules.
    6. Validates and deploys infra/arm/azuredeploy.json.
    7. Runs Configure-ContainerApp.ps1 to connect the Container App to Azure SQL
       Database and Azure Container Registry.

    The password reaches Azure CLI only through a temporary parameters file that
    the script deletes when it finishes. The script prints only non-secret values.

    You need the Owner role (or Contributor plus User Access Administrator) on the
    subscription, because the template creates a role assignment and the script
    registers resource providers.

.PARAMETER ResourceGroupName
    Name of the dedicated lab resource group. The script creates it if it doesn't exist.

.PARAMETER Location
    Azure region for the resource group and resources, for example the value
    returned by "az account list-locations --query [].name".

.PARAMETER SubscriptionId
    Optional subscription ID. Defaults to the current Azure CLI subscription.

.PARAMETER SqlAdministratorPassword
    Optional SecureString password for the Azure SQL administrator (caldovaadmin).
    If you omit it, the script prompts for it.

.PARAMETER SkipProviderRegistration
    Skips Register-ResourceProviders.ps1.

.EXAMPLE
    ./scripts/setup/Deploy-LabInfrastructure.ps1 -ResourceGroupName rg-caldova-lab -Location eastus
#>
#Requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[-\w\.\(\)]{1,90}$')]
    [ValidateScript({ -not $_.EndsWith('.') })]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$Location,

    [string]$SubscriptionId,

    [securestring]$SqlAdministratorPassword,

    [switch]$SkipProviderRegistration
)

$ErrorActionPreference = 'Stop'

$deploymentName = 'caldova-lab'
$sqlAdministratorLogin = 'caldovaadmin'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$templateFile = Join-Path $repoRoot 'infra' 'arm' 'azuredeploy.json'

function Invoke-AzCli {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $output = & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        $shown = $Arguments[0..([Math]::Min(2, $Arguments.Count - 1))] -join ' '
        throw "Azure CLI command failed (exit code $LASTEXITCODE): az $shown"
    }
    return $output
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

function Test-SqlPasswordRule {
    # Writes one message for each Azure SQL password rule that the password breaks.
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Password,
        [Parameter(Mandatory)][string]$Login
    )

    if ($Password.Length -lt 8 -or $Password.Length -gt 128) {
        Write-Output 'Use 8 to 128 characters.'
    }

    if ($Password -ne $Password.Trim()) {
        Write-Output "Don't start or end the password with a space."
    }

    $categories = 0
    if ($Password -cmatch '[A-Z]') { $categories++ }
    if ($Password -cmatch '[a-z]') { $categories++ }
    if ($Password -match '[0-9]') { $categories++ }
    if ($Password -match '[^A-Za-z0-9]') { $categories++ }
    if ($categories -lt 3) {
        Write-Output 'Use characters from at least three of these categories: uppercase letters, lowercase letters, digits, and symbols.'
    }

    for ($i = 0; $i -le $Login.Length - 3; $i++) {
        if ($Password.IndexOf($Login.Substring($i, 3), [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Write-Output "Don't include three or more consecutive characters from the login name '$Login'."
            break
        }
    }
}

function New-NameSuffix {
    # 8 characters: a lowercase letter followed by lowercase letters and digits.
    # Valid for every resource name in the template, including the container registry
    # (alphanumeric only) and the Container App (32 characters or fewer).
    $letters = 'abcdefghijklmnopqrstuvwxyz'
    $characters = 'abcdefghijklmnopqrstuvwxyz0123456789'
    $suffix = [string]$letters[(Get-Random -Maximum $letters.Length)]
    for ($i = 1; $i -lt 8; $i++) {
        $suffix += [string]$characters[(Get-Random -Maximum $characters.Length)]
    }
    return $suffix
}

function Test-NameSuffixAvailable {
    param(
        [Parameter(Mandatory)][string]$Suffix,
        [Parameter(Mandatory)][string]$Subscription
    )

    $registryAvailable = Invoke-AzCli -Arguments @('acr', 'check-name', '--name', "acrcaldova$Suffix", '--query', 'nameAvailable', '--output', 'tsv')
    if ($registryAvailable -ne 'true') {
        return $false
    }

    $bodyFile = New-PrivateTempFile
    try {
        $body = @{ name = "sql-caldova-$Suffix"; type = 'Microsoft.Sql/servers' } | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText($bodyFile, $body)
        $url = "https://management.azure.com/subscriptions/$Subscription/providers/Microsoft.Sql/checkNameAvailability?api-version=2023-08-01"
        $sqlAvailable = Invoke-AzCli -Arguments @('rest', '--method', 'post', '--url', $url, '--body', "@$bodyFile", '--query', 'available', '--output', 'tsv')
    }
    finally {
        Remove-Item -LiteralPath $bodyFile -Force -ErrorAction SilentlyContinue
    }

    return ($sqlAvailable -eq 'true')
}

$parametersFile = $null
$plainPassword = $null

try {
    # 1. Azure CLI sign-in and subscription
    & az account show --output none 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Azure CLI is not signed in. Run "az login --use-device-code", and then run this script again.'
    }

    if ($SubscriptionId) {
        Invoke-AzCli -Arguments @('account', 'set', '--subscription', $SubscriptionId, '--only-show-errors') | Out-Null
    }

    $account = (Invoke-AzCli -Arguments @('account', 'show', '--output', 'json')) -join "`n" | ConvertFrom-Json
    $subscription = $account.id
    Write-Host "Subscription: $($account.name) ($subscription)"

    if (-not (Test-Path -LiteralPath $templateFile)) {
        throw "Template not found: $templateFile"
    }

    # 2. Region and resource providers
    $Location = $Location.ToLowerInvariant().Replace(' ', '')
    $knownLocation = Invoke-AzCli -Arguments @('account', 'list-locations', '--query', "[?name=='$Location'].name", '--output', 'tsv')
    if (-not $knownLocation) {
        throw "'$Location' isn't an Azure region name for this subscription. List the valid names with: az account list-locations --query `"[].name`" --output tsv"
    }

    if (-not $SkipProviderRegistration) {
        & (Join-Path $PSScriptRoot 'Register-ResourceProviders.ps1')
    }

    # 3. Resource group and name suffix
    $nameSuffix = $null
    $groupExists = (Invoke-AzCli -Arguments @('group', 'exists', '--name', $ResourceGroupName)) -eq 'true'
    if ($groupExists) {
        $groupLocation = Invoke-AzCli -Arguments @('group', 'show', '--name', $ResourceGroupName, '--query', 'location', '--output', 'tsv')
        if ($groupLocation -ne $Location) {
            Write-Warning "Resource group '$ResourceGroupName' already exists in '$groupLocation'. The lab resources are deployed to '$groupLocation'."
            $Location = $groupLocation
        }

        $existingSuffix = & az deployment group show --resource-group $ResourceGroupName --name $deploymentName --query 'properties.parameters.nameSuffix.value' --output tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and $existingSuffix) {
            $nameSuffix = [string]$existingSuffix
            Write-Host "Reusing the resource name suffix '$nameSuffix' from the earlier deployment."
        }
    }
    else {
        Write-Host "Creating resource group '$ResourceGroupName' in '$Location'."
        Invoke-AzCli -Arguments @('group', 'create', '--name', $ResourceGroupName, '--location', $Location, '--output', 'none', '--only-show-errors') | Out-Null
    }

    if (-not $nameSuffix) {
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            $candidate = New-NameSuffix
            if (Test-NameSuffixAvailable -Suffix $candidate -Subscription $subscription) {
                $nameSuffix = $candidate
                break
            }
            Write-Host "The names for suffix '$candidate' are already in use. Trying another suffix."
        }
        if (-not $nameSuffix) {
            throw 'Could not find an available resource name suffix after 5 attempts.'
        }
        Write-Host "Resource name suffix: $nameSuffix"
    }

    # 4. Azure SQL administrator password
    if ($SqlAdministratorPassword) {
        $plainPassword = [System.Net.NetworkCredential]::new('', $SqlAdministratorPassword).Password
        $problems = @(Test-SqlPasswordRule -Password $plainPassword -Login $sqlAdministratorLogin)
        if ($problems.Count -gt 0) {
            throw "The Azure SQL administrator password doesn't meet the requirements: $($problems -join ' ')"
        }
    }
    else {
        Write-Host ''
        Write-Host "Choose a password for the Azure SQL administrator '$sqlAdministratorLogin'. You enter it again in Exercise 9."
        while ($true) {
            $first = Read-Host 'Enter the Azure SQL administrator password' -AsSecureString
            $second = Read-Host 'Confirm the Azure SQL administrator password' -AsSecureString
            $plainFirst = [System.Net.NetworkCredential]::new('', $first).Password
            $plainSecond = [System.Net.NetworkCredential]::new('', $second).Password

            if ($plainFirst -cne $plainSecond) {
                Write-Warning 'The passwords do not match. Try again.'
                continue
            }

            $problems = @(Test-SqlPasswordRule -Password $plainFirst -Login $sqlAdministratorLogin)
            if ($problems.Count -gt 0) {
                $problems | ForEach-Object { Write-Warning $_ }
                continue
            }

            $SqlAdministratorPassword = $first
            $plainPassword = $plainFirst
            break
        }
        $plainFirst = $null
        $plainSecond = $null
    }

    # 5. Temporary parameters file (deleted in finally)
    $parametersFile = New-PrivateTempFile
    $parameters = [ordered]@{
        '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
        contentVersion = '1.0.0.0'
        parameters     = [ordered]@{
            nameSuffix               = @{ value = $nameSuffix }
            sqlAdministratorPassword = @{ value = $plainPassword }
        }
    }
    [System.IO.File]::WriteAllText($parametersFile, ($parameters | ConvertTo-Json -Depth 5))
    $plainPassword = $null

    # 6. Validate, and then deploy
    Write-Host 'Validating the deployment.'
    Invoke-AzCli -Arguments @(
        'deployment', 'group', 'validate',
        '--resource-group', $ResourceGroupName,
        '--name', $deploymentName,
        '--template-file', $templateFile,
        '--parameters', "@$parametersFile",
        '--output', 'none',
        '--only-show-errors'
    ) | Out-Null

    Write-Host 'Deploying the lab infrastructure. This can take several minutes.'
    $outputsJson = Invoke-AzCli -Arguments @(
        'deployment', 'group', 'create',
        '--resource-group', $ResourceGroupName,
        '--name', $deploymentName,
        '--template-file', $templateFile,
        '--parameters', "@$parametersFile",
        '--query', 'properties.outputs',
        '--output', 'json',
        '--only-show-errors'
    )
    $outputs = ($outputsJson -join "`n") | ConvertFrom-Json

    # 7. Container App configuration (secret, registry identity, environment variable)
    & (Join-Path $PSScriptRoot 'Configure-ContainerApp.ps1') `
        -ResourceGroupName $ResourceGroupName `
        -NameSuffix $nameSuffix `
        -SqlAdministratorPassword $SqlAdministratorPassword

    Write-Host ''
    Write-Host 'The lab infrastructure is ready. Record the resource group name for Exercise 9.'
    [pscustomobject][ordered]@{
        ResourceGroup            = $outputs.resourceGroup.value
        Location                 = $Location
        SqlServer                = $outputs.sqlServerName.value
        SqlServerFqdn            = $outputs.sqlServerFqdn.value
        Database                 = $outputs.databaseName.value
        SqlAdministratorLogin    = $outputs.sqlAdministratorLogin.value
        Registry                 = $outputs.registryName.value
        RegistryLoginServer      = $outputs.registryLoginServer.value
        ContainerAppsEnvironment = $outputs.environmentName.value
        ContainerApp             = $outputs.containerAppName.value
        ApplicationUrl           = $outputs.applicationUrl.value
    } | Format-List
}
finally {
    if ($parametersFile) {
        Remove-Item -LiteralPath $parametersFile -Force -ErrorAction SilentlyContinue
    }
    $plainPassword = $null
}
