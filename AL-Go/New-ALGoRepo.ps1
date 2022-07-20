﻿function New-ALGoRepo {
    Param(
        $tmpFolder = (Join-Path (Get-TempDir) ([Guid]::NewGuid().ToString())),
        [Parameter(Mandatory=$true)]
        $org,
        [Parameter(Mandatory=$true)]
        $repo,
        $branch = "main",
        [Parameter(Mandatory=$true)]
        [ValidateSet('PTE','AppSource')]
        $appType,
        [Parameter(Mandatory=$true)]
        [ValidateSet('public','private')]
        $accessControl,
        [Parameter(Mandatory=$true)]
        [string] $country,
        $apps = @(),
        [int] $versioningStrategy = 16,
        [switch] $updateDependencies,
        [switch] $generateDependencyArtifact,
        [string] $repoVersion = "",
        $readme = "# $repo",
        $gitHubRunner = "windows-latest",
        [string] $keyVaultName,
        [switch] $useOrgSecrets,
        [string[]] $additionalCountries = @(),
        [switch] $additionalCountriesAlways,
        [string] $nextMajorSchedule,
        [string] $nextMinorSchedule,
        [string] $currentschedule,
        [HashTable] $secrets
    )

    # Well known AppIds
    $systemAppId = "63ca2fa4-4f03-4f2b-a480-172fef340d3f"
    $baseAppId = "437dbf0e-84ff-417a-965d-ed2bb9650972"
    $applicationAppId = "c1335042-3002-4257-bf8a-75c898ccb1b8"
    $permissionsMockAppId = "40860557-a18d-42ad-aecb-22b7dd80dc80"
    $testRunnerAppId = "23de40a6-dfe8-4f80-80db-d70f83ce8caf"
    $anyAppId = "e7320ebb-08b3-4406-b1ec-b4927d3e280b"
    $libraryAssertAppId = "dd0be2ea-f733-4d65-bb34-a28f4624fb14"
    $libraryVariableStorageAppId = "5095f467-0a01-4b99-99d1-9ff1237d286f"
    $systemApplicationTestLibraryAppId = "9856ae4f-d1a7-46ef-89bb-6ef056398228"
    $TestsTestLibrariesAppId = "5d86850b-0d76-4eca-bd7b-951ad998e997"
    $performanceToolkitAppId = "75f1590f-55c5-4501-ae63-bada5534e852"
    
    $performanceToolkitApps = @($performanceToolkitAppId)
    $testLibrariesApps = @($systemApplicationTestLibraryAppId, $TestsTestLibrariesAppId)
    $testFrameworkApps = @($anyAppId, $libraryAssertAppId, $libraryVariableStorageAppId) + $testLibrariesApps
    $testRunnerApps = @($permissionsMockAppId, $testRunnerAppId) + $performanceToolkitApps + $testLibrariesApps + $testFrameworkApps

    function SetSetting {
        Param(
            [PSCustomObject] $settings,
            [string] $name,
            $value
        )

        Write-Host "Set $name=$value"
        if ($settings.PSObject.Properties.Name -eq $name) {
            $settings."$name" = $value
        }
        else {
            $settings | Add-Member -MemberType NoteProperty -Name $name -Value $value
        }
    }

    function GetUniqueFolderName {
        Param(
            [string] $baseFolder,
            [string] $folderName
        )
    
        $i = 2
        $name = $folderName
        while (Test-Path (Join-Path $baseFolder $name)) {
            $name = "$folderName($i)"
            $i++
        }
        $name
    }

    function getfiles {
        Param(
            [string] $path
        )
    
        $tempdir = $false
        if ($path -like "https://*" -or $path -like "http://*") {
            $url = $path
            $path = Join-Path $env:TEMP "$([Guid]::NewGuid().ToString()).app"
            $tempdir = $true
            Download-File -sourceUrl $url -destinationFile $path
            if (!(Test-Path -Path $path)) {
                throw "could not download the file."
            }
        }
        expandfile -path $path
        if ($tempdir) {
            Remove-Item $path -Force -ErrorAction SilentlyContinue
        }
    }
    
    function expandfile {
        Param(
            [string] $path
        )

        if (Test-Path -Path $path -PathType Container) {
            $appFolders = @()
            if (Test-Path (Join-Path $path 'app.json')) {
                $appFolders += @($path)
            }
            Get-ChildItem $path -Directory -Recurse | Where-Object { Test-Path -Path (Join-Path $_.FullName 'app.json') } | ForEach-Object {
                if (!($appFolders -contains $_.Parent.FullName)) {
                    $appFolders += @($_.FullName)
                }
            }
            $appFolders | ForEach-Object {
                $newFolder = Join-Path $env:TEMP "$([Guid]::NewGuid().ToString())"
                write-Host "$_ -> $newFolder"
                Copy-Item -Path $_ -Destination $newFolder -Force -Recurse
                Write-Host "done"
                $newFolder
            }
            Get-ChildItem $path -include @("*.zip", "*.app") -Recurse | ForEach-Object {
                expandfile $_.FullName
            }
        }
        elseif (-not (Test-Path -Path $path -PathType Leaf)) {
            throw "Path $path does not exist"
        }    
        elseif ([string]::new([char[]](Get-Content $path -Encoding byte -TotalCount 2)) -eq "PK") {
            # .zip file
            $destinationPath = Join-Path $env:TEMP "$([Guid]::NewGuid().ToString())"
            Expand-7zipArchive -path $path -destinationPath $destinationPath
            $directoryInfo = Get-ChildItem $destinationPath | Measure-Object
            if ($directoryInfo.count -eq 0) {
                throw "The file is empty or malformed."
            }      
            expandfile -path $destinationPath
            Remove-Item -Path $destinationPath -Force -Recurse -ErrorAction SilentlyContinue
        }
        elseif ([string]::new([char[]](Get-Content $path -Encoding byte -TotalCount 4)) -eq "NAVX") {
            $destinationPath = Join-Path $env:TEMP "$([Guid]::NewGuid().ToString())"
            Extract-AppFileToFolder -appFilename $path -appFolder $destinationPath -generateAppJson
            $destinationPath        
        }
        else {
            throw "The provided file cannot be extracted. The url might be wrong or the file is malformed."
        }
    }

    try {
        invoke-git --version
    }
    catch {
        throw "You need to install Git (https://git-scm.com/) in order to use the AL-Go for GitHub setup function."
    }
    
    try {
        invoke-gh --version | Where-Object { $_ -like 'gh*' }
        invoke-gh auth status
    }
    catch {
        throw "You need to install GitHub CLI (https://cli.github.com/) in order to use the AL-Go for GitHub setup function."
    }

    try {
        $azModule = get-installedmodule -name az
        Write-Host "Az PS Module Version $($azModule.Version)"
        $context = Get-AzContext
        if (-not ($context)) {
            throw "You must run Login-AzAccount and Set-AzContext to select account and subscription"
        }
        Write-Host $context.Name
    }
    catch {
        throw "You need to install the Az PowerShell module Azure CLI (https://www.powershellgallery.com/packages/Az) in order to use the AL-Go for GitHub setup function."
    }

    if (Test-Path $tmpFolder) {
        throw "Specified folder already exists"
    }

    if ($repoVersion) {
        try {
            $version = [Version]"$repoVersion.0.0"
        }
        catch {
            throw "repoVersion is not correctly formatted, needs to be major.minor"
        }
    }
    else {
        $version = [Version]"0.0.0.0"
    }

    if ($useOrgSecrets) {
        Write-Host -ForegroundColor Yellow "NOTE: You need to make sure your organization secrets are accessible from the repo here: https://github.com/organizations/$org/settings/secrets/actions"
    }
    elseif ($keyVaultName) {
        $keyvault = Get-AzKeyVault -name $keyVaultName -WarningAction SilentlyContinue
        $context = Get-AzContext
        if (-not ($keyVault)) {
            throw "KeyVault doesn't exist"
        }
    }

    New-Item -Path $tmpFolder -ItemType Directory | Out-Null
    Set-Location $tmpFolder

    $repository = "$org/$repo"
    invoke-gh repo create $repository --$accessControl --clone
    $folder = Join-Path $tmpFolder $repo
    Set-Location $folder

    Write-Host "Downloading and applying AL-Go-$AppType template"
    $templateUrl = "https://github.com/microsoft/AL-Go-$AppType/archive/refs/heads/main.zip"
    $tempZip = Join-Path (Get-TempDir) "$([Guid]::NewGuid().ToString()).zip"
    Download-File -sourceUrl $templateUrl -destinationFile $tempZip
    Expand-7zipArchive -Path $tempZip -DestinationPath $folder
    Remove-Item -Path $tempZip -Force
    Copy-Item -Path "AL-Go-$appType-main\*" -Recurse -Destination . -Force
    Remove-Item -Path "AL-Go-$appType-main" -Recurse -Force

    Write-Host "Committing and pushing template"
    invoke-git -silent add *
    invoke-git -silent commit --allow-empty -m 'template'
    invoke-git -silent branch -M $branch
    invoke-git -silent remote set-url origin "https://github.com/$repository.git"
    invoke-git -silent push --set-upstream origin $branch

    Write-Host "Reading Settings"
    $repoSettingsFile = Join-Path $folder ".github\AL-Go-Settings.json"
    $repoSettings = Get-Content $repoSettingsFile -Encoding UTF8 | ConvertFrom-Json

    $projectSettingsFile = Join-Path $folder ".AL-Go\Settings.json"
    $projectSettings = Get-Content $projectSettingsFile -Encoding UTF8 | ConvertFrom-Json

    Rename-Item -Path "al.code-workspace" -NewName "$repo.code-workspace"
    $workspaceFile = Join-Path $folder "$repo.code-workspace"
    $workspace = Get-Content $workspaceFile -Encoding UTF8 | ConvertFrom-Json

    Write-Host "Updating settings"
    if ($gitHubRunner -and $gitHubRunner -ne "Windows-Latest") {
        SetSetting -settings $repoSettings -name "GitHubRunner" -value $gitHubRunner
    }

    SetSetting -settings $projectSettings -name "Country" -value $country
    if ($additionalCountriesAlways) {
        SetSetting -settings $projectSettings -name "AdditionalCountries" -value $additionalCountries
    }

    if ($apps) {
        $apps | ForEach-Object {
            getfiles -path $_ | ForEach-Object {
                $appFolder = $_
                "?Content_Types?.xml", "MediaIdListing.xml", "navigation.xml", "NavxManifest.xml", "DocComments.xml", "SymbolReference.json" | ForEach-Object {
                    Remove-Item (Join-Path $appFolder $_) -Force -ErrorAction SilentlyContinue
                }
                $appJson = Get-Content (Join-Path $appFolder "app.json") -Encoding UTF8 | ConvertFrom-Json

                $ranges = @()
                if ($appJson.PSObject.Properties.Name -eq "idRanges") {
                    $ranges += $appJson.idRanges
                }
                if ($appJson.PSObject.Properties.Name -eq "idRange") {
                    $ranges += @($appJson.idRange)
                }
        
                $ttype = ""
                $ranges | Select-Object -First 1 | ForEach-Object {
                    if ($_.from -lt 100000 -and $_.to -lt 100000) {
                        $ttype = "PTE"
                    }
                    else {
                        $ttype = "AppSource App" 
                    }
                }
        
                if ($appJson.PSObject.Properties.Name -eq "dependencies") {
                    $appJson.dependencies | ForEach-Object {
                        if ($_.PSObject.Properties.Name -eq "AppId") {
                            $id = $_.AppId
                        }
                        else {
                            $id = $_.Id
                        }
                        if ($testRunnerApps.Contains($id)) { 
                            $ttype = "Test App"
                        }
                    }
                }

                if ($ttype -ne "Test App") {
                    Get-ChildItem -Path $appFolder -Filter "*.al" -Recurse | ForEach-Object {
                        $alContent = (Get-Content -Path $_.FullName -Encoding UTF8) -join "`n"
                        if ($alContent -like "*codeunit*subtype*=*test*[test]*") {
                            $ttype = "Test App"
                        }
                    }
                }

                if ($ttype -ne "Test App" -and $ttype -ne $AppType) {
                    Write-Host -ForegroundColor Yellow "You are adding a $ttype app into a $appType repository"
                }

                $orgfolderName = $appJson.name.Split([System.IO.Path]::getInvalidFileNameChars()) -join ""
                $folderName = GetUniqueFolderName -baseFolder $folder -folderName $orgfolderName
                if ($folderName -ne $orgfolderName) {
                    Write-Host -ForegroundColor Yellow "$orgFolderName already exists as a folder in the repo, using $folderName instead"
                }

                Move-Item -Path $appFolder -Destination $folder -Force
                Rename-Item -Path ([System.IO.Path]::GetFileName($appFolder)) -NewName $folderName
                $appFolder = Join-Path $folder $folderName

                Get-ChildItem $appFolder -Filter '*.*' -Recurse | ForEach-Object {
                    if ($_.Name.Contains('%20')) {
                        Rename-Item -Path $_.FullName -NewName $_.Name.Replace('%20', ' ')
                    }
                }

                if ($ttype -eq "Test App") {
                    $projectSettings.TestFolders += @($folderName)
                }
                else {
                    $projectSettings.AppFolders += @($folderName)
                }

                if (-not ($workspace.folders | Where-Object { $_.Path -eq $foldername })) {
                    $workspace.folders += @(@{ "path" = $foldername })
                }
            }
        }
    }

    Write-Host "Analyzing app version numbers"
    $maxVersionNumber = [Version]"0.0.0.0"
    $maxBuildNo = 0
    $projectSettings.AppFolders+$projectSettings.TestFolders | ForEach-Object {
        $appJsonFile = Join-Path $folder "$_\app.json"
        $appJson = Get-Content $appJsonFile -Encoding UTF8 | ConvertFrom-Json
        $appVersion = [Version]$appJson.Version
        if ($appVersion -gt $maxVersionNumber) {
            $maxVersionNumber = $appVersion
        }
        if ($appVersion.Build -ge $maxBuildNo) {
            $maxBuildNo = $appVersion.Build+1
        }
    }

    if (($VersioningStrategy -band 16) -eq 16) {
        if (-not ($repoVersion)) {
            $repoVersion = "$($maxVersionNumber.Major).$($maxVersionNumber.Minor+1)"
            $version = [Version]"$repoVersion.0.0"
        }
        $projectSettings.AppFolders+$projectSettings.TestFolders | ForEach-Object {
            $appJsonFile = Join-Path $folder "$_\app.json"
            $appJson = Get-Content $appJsonFile -Encoding UTF8 | ConvertFrom-Json
            $appVersion = [Version]$appJson.Version
            if ([Version]$appJson.Version -gt $version) {
                Write-Host -ForegroundColor Yellow "WARNING: Version number of app in $_ was $($appJson.Version), will be set to $version, meaning that you will not be able to upgrade existing installations to this new version"
            }
            $appJson.Version = "$version"
            $appJson | ConvertTo-Json -Depth 99 | Set-Content $appJsonFile -Encoding UTF8
        }
    }
    else {
        $repoVersion = "1.0"
        if (($versioningStrategy -band 15) -eq 0) {
            SetSetting -settings $repoSettings -name "RunNumberOffset" -value $maxBuildNo
        }
    }

    SetSetting -settings $repoSettings -name "RepoVersion" -value $repoVersion
    SetSetting -settings $repoSettings -name "UpdateDependencies" -value $updateDependencies.IsPresent
    SetSetting -settings $repoSettings -name "GenerateDependencyArtifact" -value $generateDependencyArtifact.IsPresent

    $orgSecrets = @(invoke-gh -returnValue secret list --org $Org -ErrorAction SilentlyContinue)

    if ($keyVaultName) {
        if ($useOrgSecrets -and ($orgSecrets | Where-Object { $_ -like "AZURE_CREDENTIALS`t*" })) {
            SetSetting -settings $repoSettings -name "KeyVaultName" -value $keyvault.VaultName
        }
        else {
            if (!$secrets.Contains('AZURE_CREDENTIALS')) {
                $secrets.AZURE_CREDENTIALS = "$org/$repo"
            }
            if (!$secrets.AZURE_CREDENTIALS.StartsWith('{')) {
                Write-Host "Creating Service Principal for $($secrets.AZURE_CREDENTIALS) to access KeyVault $keyVaultName using get, list"
                $adsp = New-AzADServicePrincipal -DisplayName $secrets.AZURE_CREDENTIALS -Role reader -Scope "/subscriptions/$($context.Subscription.Id)/resourceGroups/$($keyvault.ResourceGroupName)/providers/Microsoft.KeyVault/vaults/$($keyvault.VaultName)"
                Set-AzKeyVaultAccessPolicy -VaultName $keyvault.VaultName -PermissionsToSecrets get,list -ObjectId $adsp.Id
                $authContext = @{
                    "clientId" = $adsp.AppId
                    "clientSecret" = $adsp.PasswordCredentials.secrettext
                    "subscriptionId" = $context.Subscription.Id
                    "tenantId" = $context.Tenant.Id
                    "KeyVaultName" = $keyvault.VaultName
                }
                $secrets.AZURE_CREDENTIALS = "$($authContext | ConvertTo-Json -Compress)"
            }
            if ($useOrgSecrets) {
                Write-Host "Creating organizational secret AZURE_CREDENTIALS with access to KeyVault"
                invoke-gh -silent secret set AZURE_CREDENTIALS --org $Org --body $secrets.AZURE_CREDENTIALS --visibility selected --repos $repo
            }
            else {
                Write-Host "Creating repository secret AZURE_CREDENTIALS with access to KeyVault"
                invoke-gh -silent secret set AZURE_CREDENTIALS --body $secrets.AZURE_CREDENTIALS
            }
        }
    }

    $secrets.Keys | ForEach-Object {
        $key = $_
        $value = $secrets."$key"
        if ($key -ne "AZURE_CREDENTIALS" -and ($value)) {
            if ($useOrgSecrets) {
                Write-Host "Creating organizational secret $key with value $value in $Org"
                invoke-gh -silent secret set $key --org $Org --body $value --visibility selected --repos $repo
            }
            else {
                Write-Host "Creating repository secret $key"
                invoke-gh -silent secret set $key --body $value
            }
        }
    }

    'NextMajor','NextMinor','Current' | ForEach-Object {
        $name = "$($_)Schedule"
        $value = (Get-Variable $name).Value
        $workflowFile = ".github\workflows\$_.yaml"
        $srcContent = (Get-Content -Path $workflowFile -Encoding UTF8 -Raw).Replace("`r", "").TrimEnd("`n").Replace("`n", "`r`n")
        if ($value) {
            SetSetting -settings $repoSettings -name $name -value $value
            $srcPattern = "on:`r`n  workflow_dispatch:`r`n"
            $replacePattern = "on:`r`n  schedule:`r`n  - cron: '$($value)'`r`n  workflow_dispatch:`r`n"
            $srcContent = $srcContent.Replace($srcPattern, $replacePattern)
            Set-Content -Path $workflowFile -Encoding UTF8 -Value $srcContent
        }
        if (!$additionalCountriesAlways) {
            $workflowSettingsFile = Join-Path $folder ".github\$($srcContent.Split("`r")[0].Substring(6)).settings.json"
            $workflowSettings = Get-Content $workflowSettingsFile -Encoding UTF8 | ConvertFrom-Json
            SetSetting -settings $workflowSettings -name "AdditionalCountries" -value $additionalCountries
            $workflowSettings | ConvertTo-Json -Depth 99 | Set-Content -Path $workflowSettingsFile -Encoding UTF8
        }
    }

    Write-Host "Writing Settings"
    $repoSettings | ConvertTo-Json -Depth 99 | Set-Content -Path $repoSettingsFile -Encoding UTF8
    $projectSettings | ConvertTo-Json -Depth 99 | Set-Content -Path $projectSettingsFile -Encoding UTF8
    $workspace | ConvertTo-Json -Depth 99 | Set-Content -Path $workspaceFile -Encoding UTF8

    Write-Host "Setting README.md content"
    Set-Content -Path (Join-Path $folder "README.md") -Value $readme

    Write-Host "Pushing Changes"
    invoke-git -silent add *
    invoke-git -silent commit --allow-empty -m "initial commit"
    invoke-git -silent push

    $tmpFolder
}
Export-ModuleMember -Function New-ALGoRepo
