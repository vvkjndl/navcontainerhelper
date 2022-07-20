﻿<# 
 .Synopsis
  Function for creating a Business Central online environment
 .Description
  Function for creating a Business Central online environment
  This function is a wrapper for https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/administration-center-api#create-new-environment
 .Parameter bcAuthContext
  Authorization Context created by New-BcAuthContext.
 .Parameter applicationFamily
  Application Family in which the environment is located. Default is BusinessCentral.
 .Parameter environment
  Name of the new environment
 .Parameter countryCode
  Country code of the new environment
 .Parameter environmentType
  Type of the new environment. Default is Sandbox.
 .Parameter ringName
  The logical ring group to create the environment within
 .Parameter applicationVersion
  The version of the application the environment should be created on
 .Parameter applicationInsightsKey
  Application Insights Key to add to the environment
 .Parameter doNotWait
  Include this switch if you don't want to wait for completion of the environment
 .Example
  $authContext = New-BcAuthContext -includeDeviceLogin
  New-BcEnvironment -bcAuthContext $authContext -countryCode 'us' -environment 'usSandbox'
#>
function New-BcEnvironment {
    Param(
        [Parameter(Mandatory=$true)]
        [Hashtable] $bcAuthContext,
        [string] $applicationFamily = "BusinessCentral",
        [Parameter(Mandatory=$true)]
        [string] $environment,
        [Parameter(Mandatory=$true)]
        [string] $countryCode,
        [ValidateSet('Sandbox','Production')]
        [string] $environmentType = "Sandbox",
        [string] $ringName = "PROD",
        [string] $applicationVersion = "",
        [string] $applicationInsightsKey = "",
        [switch] $doNotWait
    )

$telemetryScope = InitTelemetryScope -name $MyInvocation.InvocationName -parameterValues $PSBoundParameters -includeParameters @()
try {

    $bcAuthContext = Renew-BcAuthContext -bcAuthContext $bcAuthContext
    if (Get-BcEnvironments -bcAuthContext $bcAuthContext | Where-Object { $_.Status -eq 'Preparing'}) {
        Write-Host -NoNewline "Waiting for other environments."
        while (Get-BcEnvironments -bcAuthContext $bcAuthContext | Where-Object { $_.Status -eq 'Preparing'}) {
            Start-Sleep -Seconds 2
            Write-Host -NoNewline "."
        }
        Write-Host " done"
    }

    $bcAuthContext = Renew-BcAuthContext -bcAuthContext $bcAuthContext
    $bearerAuthValue = "Bearer $($bcAuthContext.AccessToken)"
    $headers = @{
        "Authorization" = $bearerAuthValue
    }
    $body = @{}
    "environmentType","countryCode","applicationVersion","ringName" | % {
        $var = Get-Variable -Name $_ -ErrorAction SilentlyContinue
        if ($var -and $var.Value -ne "") {
            $body += @{
                "$_" = $var.Value
            }
        }
    }

    Write-Host "Submitting new environment request for $applicationFamily/$environment"
    $body | ConvertTo-Json | Out-Host
    try {
        Invoke-RestMethod -Method PUT -Uri "$($bcContainerHelperConfig.apiBaseUrl.TrimEnd('/'))/admin/v2.3/applications/$applicationFamily/environments/$environment" -Headers $headers -Body ($Body | ConvertTo-Json) -ContentType 'application/json'
    }
    catch {
        throw (GetExtendedErrorMessage $_)
    }
    Write-Host "New environment request submitted"
    if (!$doNotWait -and !$applicationInsightsKey) {
        Write-Host -NoNewline "Preparing."
        do {
            Start-Sleep -Seconds 2
            Write-Host -NoNewline "."
            $status = (Get-BcEnvironments -bcAuthContext $bcAuthContext | Where-Object { $_.name -eq $environment }).status
        } while ($status -eq "Preparing")
        Write-Host $status
        if ($status -ne "Active") {
            throw "Could not create environment"
        }
    }
    if ($applicationInsightsKey) {
        Set-BcEnvironmentApplicationInsightsKey -bcAuthContext $bcAuthContext -applicationFamily $applicationFamily -environment $environment -applicationInsightsKey $applicationInsightsKey
    }

    if (!$doNotWait) {
        $automationApiUrl = "$($bcContainerHelperConfig.apiBaseUrl.TrimEnd('/'))/v2.0/$environment/api/microsoft/automation/v2.0"
        try {
            $companies = Invoke-RestMethod -Headers $headers -Method Get -Uri "$automationApiUrl/companies" -UseBasicParsing
        } catch {
            start-sleep -seconds 10
            $companies = Invoke-RestMethod -Headers $headers -Method Get -Uri "$automationApiUrl/companies" -UseBasicParsing
        }
        Write-Host "Companies in environment:"
        $companies.value | ForEach-Object { Write-Host "- $($_.name)" }
        $company = $companies.value | Select-Object -First 1
        $users = Invoke-RestMethod -Method Get -Uri "$automationApiUrl/companies($($company.Id))/users" -UseBasicParsing -Headers $headers
        Write-Host "Users in $($company.name):"
        $users.value | ForEach-Object { Write-Host "- $($_.DisplayName)" }
    }
}
catch {
    TrackException -telemetryScope $telemetryScope -errorRecord $_
    throw
}
finally {
    TrackTrace -telemetryScope $telemetryScope
}
}
Export-ModuleMember -Function New-BcEnvironment
