﻿<# 
 .Synopsis
  Function for retrieving Installed Extensions from an online Business Central environment (both AppSource and PTEs)
 .Description
  Function for retrieving Installed Extensions from an online Business Central environment (both AppSource and PTEs)
 .Parameter bcAuthContext
  Authorization Context created by New-BcAuthContext.
 .Parameter applicationFamily
  Application Family in which the environment is located. Default is BusinessCentral.
 .Parameter companyName
  CompanyName to use in the request. Default is the first company.
 .Parameter environment
  Environment from which you want to return the published Apps.
 .Example
  $authContext = New-BcAuthContext -includeDeviceLogin
  Get-BcInstalledExtensions -bcAuthContext $authContext -environment "Sandbox"
#>
function Get-BcInstalledExtensions {
    Param(
        [Parameter(Mandatory=$true)]
        [Hashtable] $bcAuthContext,
        [string] $applicationFamily = "BusinessCentral",
        [string] $companyName = "",
        [Parameter(Mandatory=$true)]
        [string] $environment
    )

$telemetryScope = InitTelemetryScope -name $MyInvocation.InvocationName -parameterValues $PSBoundParameters -includeParameters @()
try {
	
    $bcAuthContext = Renew-BcAuthContext -bcAuthContext $bcAuthContext
    $bearerAuthValue = "Bearer $($bcAuthContext.AccessToken)"
    $headers = @{ "Authorization" = $bearerAuthValue }

    $automationApiUrl = "$($bcContainerHelperConfig.apiBaseUrl.TrimEnd('/'))/v2.0/$environment/api/microsoft/automation/v1.0"

    $companies = Invoke-RestMethod -Headers $headers -Method Get -Uri "$automationApiUrl/companies" -UseBasicParsing
    $company = $companies.value | Where-Object { ($companyName -eq "") -or ($_.name -eq $companyName) } | Select-Object -First 1
    if (!($company)) {
        throw "No company $companyName"
    }
    $companyId = $company.id
    try {
        (Invoke-RestMethod -Headers $headers -Method Get -Uri "$automationApiUrl/companies($companyId)/extensions" -UseBasicParsing).value
    }
    catch {
        throw (GetExtendedErrorMessage $_)
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
Export-ModuleMember -Function Get-BcInstalledExtensions
