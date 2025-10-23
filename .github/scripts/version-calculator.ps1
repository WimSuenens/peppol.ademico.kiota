# Version Calculator Script
# This script reads the current version from .csproj file and calculates the next version
# based on commit messages and PR labels following semantic versioning

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$CommitMessages = "",
    
    [Parameter(Mandatory=$false)]
    [string]$PrLabels = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultIncrement = "patch"
)

# Function to read current version from .csproj file
function Get-CurrentVersion {
    param([string]$ProjectPath)
    
    if (-not (Test-Path $ProjectPath)) {
        throw "Project file not found: $ProjectPath"
    }
    
    try {
        [xml]$projectXml = Get-Content $ProjectPath
        
        # Find Version property in any PropertyGroup
        $versionNode = $null
        foreach ($propertyGroup in $projectXml.Project.PropertyGroup) {
            if ($propertyGroup.Version) {
                $versionNode = $propertyGroup.Version
                break
            }
        }
        
        if (-not $versionNode) {
            throw "Version property not found in project file"
        }
        
        # Trim whitespace from version string
        return $versionNode.Trim()
    }
    catch {
        throw "Failed to read version from project file: $_"
    }
}

# Function to parse semantic version
function Parse-SemanticVersion {
    param([string]$Version)
    
    if ($Version -match '^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$') {
        return @{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
            PreRelease = $Matches[4]
        }
    }
    else {
        throw "Invalid semantic version format: $Version"
    }
}

# Function to determine version increment type based on commit messages and PR labels
function Get-VersionIncrementType {
    param(
        [string]$CommitMessages,
        [string]$PrLabels,
        [string]$DefaultIncrement
    )
    
    # Check for breaking changes (major version increment)
    if ($CommitMessages -match "BREAKING CHANGE:" -or $PrLabels -match "breaking-change") {
        return "major"
    }
    
    # Check for features (minor version increment)
    if ($CommitMessages -match "feat:" -or $PrLabels -match "enhancement") {
        return "minor"
    }
    
    # Check for fixes or other changes (patch version increment)
    if ($CommitMessages -match "fix:" -or $CommitMessages -match "chore:" -or $CommitMessages -match "docs:") {
        return "patch"
    }
    
    # Default increment type
    return $DefaultIncrement
}

# Function to increment version based on type
function Get-NextVersion {
    param(
        [hashtable]$CurrentVersion,
        [string]$IncrementType
    )
    
    $newVersion = @{
        Major = $CurrentVersion.Major
        Minor = $CurrentVersion.Minor
        Patch = $CurrentVersion.Patch
    }
    
    switch ($IncrementType.ToLower()) {
        "major" {
            $newVersion.Major++
            $newVersion.Minor = 0
            $newVersion.Patch = 0
        }
        "minor" {
            $newVersion.Minor++
            $newVersion.Patch = 0
        }
        "patch" {
            $newVersion.Patch++
        }
        default {
            throw "Invalid increment type: $IncrementType"
        }
    }
    
    return "$($newVersion.Major).$($newVersion.Minor).$($newVersion.Patch)"
}

# Function to generate release notes based on increment type and changes
function Get-ReleaseNotes {
    param(
        [string]$IncrementType,
        [string]$CommitMessages,
        [string]$Version
    )
    
    $notes = "Version $Version - "
    
    switch ($IncrementType.ToLower()) {
        "major" {
            $notes += "Major release with breaking changes"
        }
        "minor" {
            $notes += "Minor release with new features"
        }
        "patch" {
            $notes += "Patch release with bug fixes and improvements"
        }
    }
    
    return $notes
}

# Main execution
try {
    Write-Host "Starting version calculation..." -ForegroundColor Green
    Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
    Write-Host "Commit Messages: $CommitMessages" -ForegroundColor Gray
    Write-Host "PR Labels: $PrLabels" -ForegroundColor Gray
    
    # Read current version
    $currentVersionString = Get-CurrentVersion -ProjectPath $ProjectPath
    Write-Host "Current Version: $currentVersionString" -ForegroundColor Yellow
    
    # Parse current version
    $currentVersion = Parse-SemanticVersion -Version $currentVersionString
    
    # Determine increment type
    $incrementType = Get-VersionIncrementType -CommitMessages $CommitMessages -PrLabels $PrLabels -DefaultIncrement $DefaultIncrement
    Write-Host "Increment Type: $incrementType" -ForegroundColor Yellow
    
    # Calculate next version
    $nextVersion = Get-NextVersion -CurrentVersion $currentVersion -IncrementType $incrementType
    Write-Host "Next Version: $nextVersion" -ForegroundColor Green
    
    # Generate release notes
    $releaseNotes = Get-ReleaseNotes -IncrementType $incrementType -CommitMessages $CommitMessages -Version $nextVersion
    Write-Host "Release Notes: $releaseNotes" -ForegroundColor Gray
    
    # Output results for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "current-version=$currentVersionString"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "next-version=$nextVersion"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "increment-type=$incrementType"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "release-notes=$releaseNotes"
        Write-Host "Version information written to GitHub Actions output" -ForegroundColor Green
    }
    
    # Also output as JSON for other consumers
    $result = @{
        currentVersion = $currentVersionString
        nextVersion = $nextVersion
        incrementType = $incrementType
        releaseNotes = $releaseNotes
    } | ConvertTo-Json -Compress
    
    Write-Host "JSON Output: $result" -ForegroundColor Cyan
    
    # Write to file if environment variable is set (for wrapper script)
    if ($env:VERSION_OUTPUT_FILE) {
        $result | Out-File -FilePath $env:VERSION_OUTPUT_FILE -Encoding UTF8
    }
    
    exit 0
}
catch {
    Write-Error "Version calculation failed: $_"
    exit 1
}