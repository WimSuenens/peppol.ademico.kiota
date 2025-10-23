# Update Project Version Script
# This script updates the version properties in the .csproj file

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$true)]
    [string]$NewVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseNotes = ""
)

# Function to update version in .csproj file
function Update-ProjectVersion {
    param(
        [string]$ProjectPath,
        [string]$NewVersion,
        [string]$ReleaseNotes
    )
    
    if (-not (Test-Path $ProjectPath)) {
        throw "Project file not found: $ProjectPath"
    }
    
    try {
        # Read the project file
        [xml]$projectXml = Get-Content $ProjectPath
        
        # Find or create the PropertyGroup containing version information
        $versionPropertyGroup = $projectXml.Project.PropertyGroup | Where-Object { $_.Version -ne $null }
        
        if (-not $versionPropertyGroup) {
            # If no PropertyGroup with Version exists, use the first PropertyGroup
            $versionPropertyGroup = $projectXml.Project.PropertyGroup[0]
        }
        
        # Update Version property
        if ($versionPropertyGroup.Version) {
            $versionPropertyGroup.Version = $NewVersion
        } else {
            # Create Version element if it doesn't exist
            $versionElement = $projectXml.CreateElement("Version")
            $versionElement.InnerText = $NewVersion
            $versionPropertyGroup.AppendChild($versionElement) | Out-Null
        }
        
        # Update or create AssemblyVersion property
        if ($versionPropertyGroup.AssemblyVersion) {
            $versionPropertyGroup.AssemblyVersion = $NewVersion
        } else {
            # Create AssemblyVersion element if it doesn't exist
            $assemblyVersionElement = $projectXml.CreateElement("AssemblyVersion")
            $assemblyVersionElement.InnerText = $NewVersion
            $versionPropertyGroup.AppendChild($assemblyVersionElement) | Out-Null
        }
        
        # Update or create FileVersion property
        if ($versionPropertyGroup.FileVersion) {
            $versionPropertyGroup.FileVersion = $NewVersion
        } else {
            # Create FileVersion element if it doesn't exist
            $fileVersionElement = $projectXml.CreateElement("FileVersion")
            $fileVersionElement.InnerText = $NewVersion
            $versionPropertyGroup.AppendChild($fileVersionElement) | Out-Null
        }
        
        # Update or create PackageReleaseNotes if provided
        if ($ReleaseNotes) {
            if ($versionPropertyGroup.PackageReleaseNotes) {
                $versionPropertyGroup.PackageReleaseNotes = $ReleaseNotes
            } else {
                # Create PackageReleaseNotes element if it doesn't exist
                $releaseNotesElement = $projectXml.CreateElement("PackageReleaseNotes")
                $releaseNotesElement.InnerText = $ReleaseNotes
                $versionPropertyGroup.AppendChild($releaseNotesElement) | Out-Null
            }
        }
        
        # Save the updated project file
        $projectXml.Save($ProjectPath)
        
        Write-Host "Successfully updated project version to $NewVersion" -ForegroundColor Green
        
        return $true
    }
    catch {
        throw "Failed to update project version: $_"
    }
}

# Function to validate the updated version
function Validate-UpdatedVersion {
    param(
        [string]$ProjectPath,
        [string]$ExpectedVersion
    )
    
    try {
        [xml]$projectXml = Get-Content $ProjectPath
        
        # Find the PropertyGroup with version information
        $versionPropertyGroup = $projectXml.Project.PropertyGroup | Where-Object { $_.Version -ne $null }
        
        if (-not $versionPropertyGroup) {
            Write-Warning "No PropertyGroup with Version found"
            return $false
        }
        
        # Validate Version property
        $actualVersion = $versionPropertyGroup.Version
        if ($actualVersion -ne $ExpectedVersion) {
            Write-Warning "Version validation failed. Expected: $ExpectedVersion, Actual: $actualVersion"
            return $false
        }
        
        # Validate AssemblyVersion property
        if ($versionPropertyGroup.AssemblyVersion -and $versionPropertyGroup.AssemblyVersion -ne $ExpectedVersion) {
            Write-Warning "AssemblyVersion validation failed. Expected: $ExpectedVersion, Actual: $($versionPropertyGroup.AssemblyVersion)"
            return $false
        }
        
        # Validate FileVersion property
        if ($versionPropertyGroup.FileVersion -and $versionPropertyGroup.FileVersion -ne $ExpectedVersion) {
            Write-Warning "FileVersion validation failed. Expected: $ExpectedVersion, Actual: $($versionPropertyGroup.FileVersion)"
            return $false
        }
        
        Write-Host "Version validation successful:" -ForegroundColor Green
        Write-Host "  Version: $actualVersion" -ForegroundColor Gray
        if ($versionPropertyGroup.AssemblyVersion) {
            Write-Host "  AssemblyVersion: $($versionPropertyGroup.AssemblyVersion)" -ForegroundColor Gray
        }
        if ($versionPropertyGroup.FileVersion) {
            Write-Host "  FileVersion: $($versionPropertyGroup.FileVersion)" -ForegroundColor Gray
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to validate updated version: $_"
        return $false
    }
}

# Main execution
try {
    Write-Host "Starting project version update..." -ForegroundColor Green
    Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
    Write-Host "New Version: $NewVersion" -ForegroundColor Gray
    Write-Host "Release Notes: $ReleaseNotes" -ForegroundColor Gray
    
    # Validate version format
    if (-not ($NewVersion -match '^\d+\.\d+\.\d+$')) {
        throw "Invalid version format. Expected semantic version (x.y.z): $NewVersion"
    }
    
    # Update the project version
    Update-ProjectVersion -ProjectPath $ProjectPath -NewVersion $NewVersion -ReleaseNotes $ReleaseNotes
    
    # Validate the update
    $validationResult = Validate-UpdatedVersion -ProjectPath $ProjectPath -ExpectedVersion $NewVersion
    
    if ($validationResult) {
        Write-Host "Project version update completed successfully" -ForegroundColor Green
        exit 0
    } else {
        throw "Version update validation failed"
    }
}
catch {
    Write-Error "Project version update failed: $_"
    exit 1
}