﻿<# 
 .Synopsis
  Replaces specified dependencies in an application file
 .Description
  Investigates whether the application file contains dependencies to a specific application ID and replaces the dependency if that is the case
 .Parameter Path
  Path of the application file to investigate
 .Parameter Destination
  Path of the modified application file, where dependencies was replaced (default is to rewrite the original file)
 .Parameter replaceDependencies
  A hashtable, describring the dependencies, which needs to be replaced
 .Parameter internalsVisibleTo
  An Array of hashtable, containing id, name and publisher of an app, which should be added to internals Visible to
 .Parameter showMyCode
  With this parameter you can change or check ShowMyCode in the app file. Check will throw an error if ShowMyCode is False.
 .Example
  Replace-DependenciesInAppFile -containerName test -Path c:\temp\myapp.app -replaceDependencies @{ "437dbf0e-84ff-417a-965d-ed2bb9650972" = @{ "id" = "88b7902e-1655-4e7b-812e-ee9f0667b01b"; "name" = "MyBaseApp"; "publisher" = "Freddy Kristiansen"; "minversion" = "1.0.0.0" }}
 .Example
  Replace-DependenciesInAppFile -containerName test -Path c:\temp\myapp.app -internalsVisibleTo @( @{ "id" = "88b7902e-1655-4e7b-812e-ee9f0667b01b"; "name" = "MyBaseApp"; "publisher" = "Freddy Kristiansen" } )
#>
Function Replace-DependenciesInAppFile {
    Param (
        [string] $containerName = $bcContainerHelperConfig.defaultContainerName,
        [Parameter(Mandatory=$true)]
        [string] $Path,
        [string] $Destination = $Path,
        [hashtable] $replaceDependencies = $null,
        [ValidateSet('Ignore','True','False','Check')]
        [string] $ShowMyCode = "Ignore",
        [switch] $replacePackageId,
        [HashTable[]] $internalsVisibleTo = $null
    )

$telemetryScope = InitTelemetryScope -name $MyInvocation.InvocationName -parameterValues $PSBoundParameters -includeParameters @()
try {

    if ($path -ne $Destination) {
        Copy-Item -Path $path -Destination $Destination -Force
        $path = $Destination
    }
    
    Invoke-ScriptInBCContainer -containerName $containerName -scriptBlock { Param($path, $Destination, $replaceDependencies, $ShowMyCode, $replacePackageId, $internalsVisibleTo)
    
        add-type -path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service\system.io.packaging.dll").FullName
    
        $memoryStream = $null
        $fs = $null
    
        try {
    
            $fs = [System.IO.File]::OpenRead($Path)
            $binaryReader = [System.IO.BinaryReader]::new($fs)
            $magicNumber1 = $binaryReader.ReadUInt32()
            $metadataSize = $binaryReader.ReadUInt32()
            $metadataVersion = $binaryReader.ReadUInt32()
            $packageId = [Guid]::new($binaryReader.ReadBytes(16))
            $contentLength = $binaryReader.ReadInt64()
            $magicNumber2 = $binaryReader.ReadUInt32()
            
            if ($magicNumber1 -ne 0x5856414E -or 
                $magicNumber2 -ne 0x5856414E -or 
                $metadataVersion -gt 2 -or
                $fs.Position + $contentLength -gt $fs.Length)
            {
                throw "Unsupported package format"
            }
        
            $memoryStream = [System.IO.MemoryStream]::new()
            $fs.Seek($metadataSize, [System.IO.SeekOrigin]::Begin) | Out-Null
            $fs.CopyTo($memoryStream)
            $memoryStream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
            $memoryStream.SetLength($contentLength)
            $fs.Close()
            $fs.Dispose()
            $fs = $null
            
            $package = [System.IO.Packaging.Package]::Open($memoryStream, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
            $manifestPart = $package.GetPart('/NavxManifest.xml')
            $manifest = [xml]([System.IO.StreamReader]::new($manifestPart.GetStream())).ReadToEnd()
            $manifestChanges = $false
            $symbolReferencePart = $package.GetPart('/SymbolReference.json')
            $symbolJson = ([System.IO.StreamReader]::new($symbolReferencePart.GetStream())).ReadToEnd()
            $symbolReference = $symbolJson | ConvertFrom-Json
            $symbolReferenceChanges = $false
    
            if ($ShowMyCode -ne "Ignore") {
                if ($ShowMyCode -eq "Check") {
                    $resexp = $manifest.Package.ChildNodes | Where-Object { $_.name -eq "ResourceExposurePolicy" }
                    if ($resexp) {
                        if ($resexp.allowDebugging -ne "true" -or $resexp.allowDownloadingSource -ne "true" -or $resexp.includeSourceInSymbolFile -ne "true") {
                            throw "Application has limited ResourceExposurePolicy"
                        }
                    }
                    elseif ($manifest.Package.App.ShowMyCode -eq "False") {
                        throw "Application has ShowMyCode set to False"
                    }
                } else {
                    $resexp = $manifest.Package.ChildNodes | Where-Object { $_.name -eq "ResourceExposurePolicy" }
                    if ($resexp) {
                        if ($resexp.allowDebugging -ne "$ShowMyCode" -or $resexp.allowDownloadingSource -ne "$ShowMyCode" -or $resexp.includeSourceInSymbolFile -ne "$ShowMyCode") {
                            Write-Host "Changing ResourceExposurePolicy properties to $ShowMyCode"
                            $resexp.allowDebugging = "$showMyCode"
                            $resexp.allowDownloadingSource = "$showMyCode"
                            $resexp.includeSourceInSymbolFile = "$showMyCode"
                            $manifestChanges = $true
                        }
                    }
                    elseif ($manifest.Package.App.ShowMyCode -ne $ShowMyCode) {
                        Write-Host "Changing ShowMyCode to $ShowMyCOde"
                        $manifest.Package.App.ShowMyCode = "$ShowMyCode"
                        $manifestChanges = $true
                    }
                }
            }

            if ($replaceDependencies) {
                $manifest.Package.Dependencies.GetEnumerator() | % {
                    $dependency = $_
                    if ($replaceDependencies.ContainsKey($dependency.id)) {
                        $newDependency = $replaceDependencies[$dependency.id]
                        Write-Host "Replacing dependency from $($dependency.id) to $($newDependency.id)"
                        $dependency.id = $newDependency.id
                        $dependency.name = $newDependency.name
                        $dependency.publisher = $newDependency.publisher
                        $dependency.minVersion = $newDependency.minVersion
                        $manifestChanges = $true
                    }
                }
            }

            if ($internalsVisibleTo) {
                $internalsVisibleTo | % {
                    $ivt = $_
                    $existing = $manifest.Package.InternalsVisibleTo.GetEnumerator() | Where-Object { $_.id -eq $ivt.id -and $_.name -eq $ivt.name -and $_.publisher -eq $ivt.publisher }
                    if (-not ($existing)) {
                        Write-Host "Adding Id=$($ivt.Id), Name=$($ivt.Name), Publisher=$($ivt.Publisher) to InternalsVisibleTo"
                        $element = $manifest.CreateElement("Module","http://schemas.microsoft.com/navx/2015/manifest")
                        $element.SetAttribute('Id',$ivt.Id)
                        $element.SetAttribute('Name',$ivt.Name)
                        $element.SetAttribute('Publisher',$ivt.Publisher)
                        $manifest.Package.InternalsVisibleTo.AppendChild($element) | Out-Null
                        $manifestChanges = $true

                        $symbolReference.InternalsVisibleToModules += @(@{
                            "AppId" = $ivt.Id
                            "Name" = $ivt.Name
                            "Publisher" = $ivt.Publisher
                        })
                        $symbolReferenceChanges = $true
                    }
                }
            }

            if ($replacePackageId) {
                $packageId = [Guid]::NewGuid()
                $manifestChanges = $true
            }
    
            if ($manifestChanges) {
    
                $partStream = $manifestPart.GetStream([System.IO.FileMode]::Create)
                $manifest.Save($partStream)
                $partStream.Flush()
                
                if ($symbolReferenceChanges) {
                    $partStream = $symbolReferencePart.GetStream([System.IO.FileMode]::Create)
                    $memStream = [System.IO.MemoryStream]::new()
                    $strWriter = [System.IO.StreamWriter]::new($memStream)
                    $json = $symbolreference | ConvertTo-Json -depth 99
                    $strWriter.Write($json)
                    $strWriter.Flush()
                    $memStream.Position = 0
                    $memStream.CopyTo($partStream)
                    $partStream.Flush()
                }

                $package.Close()
                
                $fs = [System.IO.FileStream]::new($Destination, [System.IO.FileMode]::Create)
                
                $binaryWriter = [System.IO.BinaryWriter]::new($fs)
                $binaryWriter.Write([UInt32](0x5856414E))
                $binaryWriter.Write([UInt32](40))
                $binaryWriter.Write([UInt32](2))
                $binaryWriter.Write($packageId.ToByteArray())
                $binaryWriter.Write([UInt64]($memoryStream.Length))
                $binaryWriter.Write([UInt32](0x5856414E))
                
                $memoryStream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
                $memoryStream.CopyTo($fs)
                
                $fs.Close()
                $fs.Dispose()
                $fs = $null
            }
            else {
                if ($Path -ne $Destination) {
                    Copy-Item -Path $Path -Destination $Destination -Force
                }
            }
        }
        finally {
            if ($fs) {
                $fs.Close()
            }
        }
    } -argumentList (Get-BCContainerPath -containerName $containerName -path $path -throw), (Get-BCContainerPath -containerName $containerName -path $Destination -throw), $replaceDependencies, $ShowMyCode, $replacePackageId, $internalsVisibleTo
}
catch {
    TrackException -telemetryScope $telemetryScope -errorRecord $_
    throw
}
finally {
    TrackTrace -telemetryScope $telemetryScope
}
}
Export-ModuleMember -Function Replace-DependenciesInAppFile
