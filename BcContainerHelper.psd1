#
# Module manifest for module 'BcContainerHelper'
#
# Generated by: Freddy Kristiansen
#
# Generated on: 31-07-2020
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'BcContainerHelper.psm1'

# Version number of this module.
ModuleVersion = '1.0.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '8e034fbc-8c30-446d-bbc3-5b3be5392491'

# Author of this module
Author = 'Freddy Kristiansen'

# Company or vendor of this module
CompanyName = 'Microsoft'

# Copyright statement for this module
Copyright = '(c) 2020 Microsoft. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PowerShell module'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Add-FontsToBcContainer', 'Add-GitToAlProjectFolder', 
               'Backup-BcContainerDatabases', 'Check-BcContainerHelperPermissions', 
               'Clean-BcContainerDatabase', 'Compile-AppInBcContainer', 
               'Compile-ObjectsInNavContainer', 'Convert-AlcOutputToDevOps', 
               'Convert-ModifiedObjectsToAl', 'Convert-Txt2Al', 'Copy-AlSourceFiles', 
               'Copy-CompanyInBcContainer', 'Copy-FileFromBcContainer', 
               'Copy-FileToBcContainer', 'Create-AlProjectFolderFromBcContainer', 
               'Create-MyDeltaFolder', 'Create-MyOriginalFolder', 
               'Create-AadAppsForNav', 'Create-AadUsersInBcContainer', 
               'New-BcAuthContext', 'Renew-BcAuthContext', 'Get-BcEnvironments', 'Get-BcPublishedApps', 'Get-ALGoAuthContext', 
               'Get-BcInstalledExtensions', 'Install-BcAppFromAppSource', 'New-BcEnvironment', 
               'Remove-BcEnvironment', 'Set-BcEnvironmentApplicationInsightsKey',
               'New-BcDatabaseExport', 'Get-BcDatabaseExportHistory',
               'Download-Artifacts', 'Download-File', 'Enter-BcContainer', 
               'Export-BcContainerDatabasesAsBacpac', 'Restore-BcDatabaseFromArtifacts',
               'Remove-BcDatabase.ps1', 'Export-ModifiedObjectsAsDeltas', 'Export-NavContainerObjects', 
               'Extract-AppFileToFolder', 'Extract-FilesFromBcContainerImage', 
               'Extract-FilesFromStoppedBcContainer', 'Flush-ContainerHelperCache', 
               'Generate-SymbolsInNavContainer', 'Get-BCArtifactUrl', 
               'Get-BcContainerApiCompanyId', 'Get-BcContainerApp', 
               'Get-BcContainerAppInfo', 'Get-BcContainerAppRuntimePackage', 
               'Convert-BcAppsToRuntimePackages', 'Get-PlainText', 
               'ConvertTo-HashTable', 'ConvertTo-OrderedDictionary', 'ConvertTo-GitHubGoCredentials',
               'Get-BcContainerArtifactUrl', 'Get-BcContainerBcUser', 
               'Get-BcContainerCountry', 'Get-BcContainerDebugInfo', 
               'Get-BcContainerEula', 'Get-BcContainerEventLog', 
               'Get-BcContainerGenericTag', 'Get-BcContainerId', 
               'Get-BcContainerImageLabels', 'Get-BcContainerImageName', 
               'Get-BcContainerImageTags', 'Get-BcContainerIpAddress', 
               'Get-BcContainerLegal', 'Get-BcContainerName', 
               'Get-BcContainerNavVersion', 'Get-BcContainerOsVersion', 
               'Get-BcContainerPath', 'Get-BcContainerPlatformVersion', 
               'Get-BcContainers', 'Get-BcContainerServerConfiguration', 
               'Get-BcContainerSession', 'Get-BcContainerSharedFolders', 
               'Get-BcContainerTenants', 'Get-BestBcContainerImageName', 
               'Get-BestGenericImageName', 'Get-CompanyInBcContainer', 
               'Get-LatestAlLanguageExtensionUrl', 'Get-AlLanguageExtensionFromArtifacts', 'Get-LocaleFromCountry', 
               'Get-NavArtifactUrl', 'Get-NavVersionFromVersionInfo', 
               'Get-TestsFromBcContainer', 'Import-BcContainerLicense', 
               'Import-ConfigPackageInBcContainer', 'Import-DeltasToNavContainer', 
               'Import-ObjectsToNavContainer', 'UploadImportAndApply-ConfigPackageInBcContainer',
               'Import-PfxCertificateToBcContainer', 'Import-CertificateToBcContainer', 
               'Import-TestToolkitToBcContainer', 'Install-BcContainerApp', 
               'Install-NAVSipCryptoProviderFromBcContainer', 
               'Invoke-BcContainerApi', 'Invoke-NavContainerCodeunit', 
               'Invoke-ScriptInBcContainer', 'New-BcContainer', 
               'New-BcContainerBcUser', 'New-BcContainerTenant', 
               'New-BcContainerWindowsUser', 'New-BcContainerWizard', 
               'New-CompanyInBcContainer', 'New-DesktopShortcut', 
               'New-LetsEncryptCertificate', 'New-NavImage', 'Open-BcContainer', 
               'Publish-BcContainerApp', 'Publish-NewApplicationToBcContainer', 
               'Remove-BcContainer', 'Remove-BcContainerSession', 
               'Remove-BcContainerTenant', 'Remove-CompanyInBcContainer', 
               'Remove-ConfigPackageInBcContainer', 'Remove-DesktopShortcut', 
               'Renew-LetsEncryptCertificate', 'Repair-BcContainerApp', 
               'Replace-DependenciesInAppFile', 'Restart-BcContainer', 'Restore-DatabasesInBcContainer', 
               'Run-TestsInBcContainer', 'Run-BCPTTestsInBcContainer', 'Run-AlPipeline', 'Run-AlValidation', 'Run-AlCops', 
               'Run-ConnectionTestToBcContainer', 'Publish-PerTenantExtensionApps', 'Publish-BuildOutputToStorage', 
               'Publish-BuildOutputToAzureFeed', 'Resolve-DependenciesFromAzureFeed', 'Install-AzDevops',
               'Set-BcContainerFeatureKeys', 'Setup-BcContainerTestUsers', 
               'Setup-TraefikContainerForBcContainers', 'Sign-BcContainerApp', 
               'Sort-AppFoldersByDependencies', 'Sort-AppFilesByDependencies', 'Start-BcContainer', 
               'Start-BcContainerAppDataUpgrade', 'Stop-BcContainer', 
               'Sync-BcContainerApp', 'Test-BcContainer', 'UnInstall-BcContainerApp', 
               'UnPublish-BcContainerApp', 'Wait-BcContainerReady', 
               'Write-BcContainerHelperWelcomeText', 'Invoke-gh', 'Invoke-git',
               'Set-BcContainerServerConfiguration', 'Restart-BcContainerServiceTier'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Add-FontsToNavContainer', 'Backup-NavContainerDatabases', 
               'Check-NavContainerHelperPermissions', 'Compile-AppInNavContainer', 
               'Copy-CompanyInNavContainer', 'Copy-FileFromNavContainer', 
               'Copy-FileToNavContainer', 'Create-AlProjectFolderFromNavContainer', 
               'Create-AadAppsForBC', 'Create-AadUsersInNavContainer', 
               'Enter-NavContainer', 'Export-NavContainerDatabasesAsBacpac', 
               'Extract-FilesFromNavContainerImage', 'Convert-AlcOutputToAzureDevOps', 
               'Extract-FilesFromStoppedNavContainer', 
               'Get-BestNavContainerImageName', 'Get-CompanyInNavContainer', 
               'Get-NavContainerApiCompanyId', 'Get-NavContainerApp', 
               'Get-NavContainerAppInfo', 'Get-NavContainerAppRuntimePackage', 
               'Get-NavContainerArtifactUrl', 'Get-NavContainerCountry', 
               'Get-NavContainerDebugInfo', 'Get-NavContainerEula', 
               'Get-NavContainerEventLog', 'Get-NavContainerGenericTag', 
               'Get-NavContainerId', 'Get-NavContainerImageLabels', 
               'Get-NavContainerImageName', 'Get-NavContainerImageTags', 
               'Get-NavContainerIpAddress', 'Get-NavContainerLegal', 
               'Get-NavContainerName', 'Get-NavContainerNavUser', 
               'Get-NavContainerNavVersion', 'Get-NavContainerOsVersion', 
               'Get-NavContainerPath', 'Get-NavContainerPlatformVersion', 
               'Get-NavContainers', 'Get-NavContainerServerConfiguration', 
               'Get-NavContainerSession', 'Get-NavContainerSharedFolders', 
               'Get-NavContainerTenants', 'Get-TestsFromNavContainer', 
               'Import-ConfigPackageInNavContainer', 'Import-NavContainerLicense', 
               'Set-BcContainerKeyVaultAadAppAndCertificate', 'Import-PfxCertificateToNavContainer', 
               'Import-TestToolkitToNavContainer', 'Install-NavContainerApp', 
               'Install-NAVSipCryptoProviderFromNavContainer', 
               'Invoke-NavContainerApi', 'Invoke-ScriptInNavContainer', 
               'New-BcImage', 'New-CompanyInNavContainer', 'New-NavContainer', 
               'New-NavContainerNavUser', 'New-NavContainerTenant', 
               'New-NavContainerWindowsUser', 'New-NavContainerWizard', 
               'Open-NavContainer', 'Publish-NavContainerApp', 
               'Publish-NewApplicationToNavContainer', 
               'Remove-CompanyInNavContainer', 
               'Get-AzureFeedWildcardVersion',
               'Remove-ConfigPackageInNavContainer', 'Remove-NavContainer', 
               'Remove-NavContainerSession', 'Remove-NavContainerTenant', 
               'Repair-NavContainerApp', 'Restart-NavContainer', 
               'Restore-DatabasesInNavContainer', 'Run-TestsInNavContainer', 
               'Setup-NavContainerTestUsers',
               'Setup-TraefikContainerForNavContainers', 'Sign-NavContainerApp', 
               'Start-NavContainer', 'Start-NavContainerAppDataUpgrade', 
               'Stop-NavContainer', 'Sync-NavContainerApp', 'Test-NavContainer', 
               'UnInstall-NavContainerApp', 'UnPublish-NavContainerApp', 
               'Wait-NavContainerReady'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/Microsoft/navcontainerhelper/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://www.github.com/microsoft/navcontainerhelper'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '1.0.1
Copy-FileToBcContainer and Copy-FileFromBcContainer didn''t support that hostHelperFolder and containerHelperFolder was different
Get-TestsFromBcContainer and Run-TestsInBcContainer didn''t support that hostHelperFolder and containerHelperFolder was different
Issue #1174 do not use hyperv isolation if Hyper-V isn''t installed'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

