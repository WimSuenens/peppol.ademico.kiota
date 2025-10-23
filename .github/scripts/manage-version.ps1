# Version Management Wrapper Script
# This script combines version calculation and project file updates

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$CommitMessages = "",
    
    [Parameter(Mandatory=$false)]
    [string]$PrLabels = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultIncrement = "patch",
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateProject = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateTag = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceTag = $false
)

$ErrorActionPreference = "Stop"

try {
    Write-Host "=== Version Management Script ===" -ForegroundColor Cyan
    
    # Get the script directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    
    # Calculate new version using a temporary file to avoid output parsing issues
    Write-Host "Step 1: Calculating new version..." -ForegroundColor Yellow
    
    # Create a temporary file for JSON output
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    try {
        # Set environment variable to write to temp file
        $env:VERSION_OUTPUT_FILE = $tempFile
        
        # Run version calculator with temp file output
        & "$scriptDir/version-calculator.ps1" -ProjectPath $ProjectPath -CommitMessages $CommitMessages -PrLabels $PrLabels -DefaultIncrement $DefaultIncrement
        
        if ($LASTEXITCODE -ne 0) {
            throw "Version calculation failed"
        }
        
        # Read JSON from temp file if it exists
        if (Test-Path $tempFile) {
            $jsonData = Get-Content $tempFile | ConvertFrom-Json
        } else {
            throw "Version calculation did not produce output file"
        }
        
        $newVersion = $jsonData.nextVersion
        $releaseNotes = $jsonData.releaseNotes
        $incrementType = $jsonData.incrementType
        
        Write-Host "Version calculation completed:" -ForegroundColor Green
        Write-Host "  Current Version: $($jsonData.currentVersion)" -ForegroundColor Gray
        Write-Host "  New Version: $newVersion" -ForegroundColor Green
        Write-Host "  Increment Type: $incrementType" -ForegroundColor Gray
        Write-Host "  Release Notes: $releaseNotes" -ForegroundColor Gray
    }
    finally {
        # Clean up temp file
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
        # Clean up environment variable
        Remove-Item Env:VERSION_OUTPUT_FILE -ErrorAction SilentlyContinue
    }
    
    # Update project file if requested
    if ($UpdateProject -and -not $DryRun) {
        Write-Host "Step 2: Updating project file..." -ForegroundColor Yellow
        & "$scriptDir/update-project-version.ps1" -ProjectPath $ProjectPath -NewVersion $newVersion -ReleaseNotes $releaseNotes
        
        if ($LASTEXITCODE -ne 0) {
            throw "Project file update failed"
        }
        
        Write-Host "Project file updated successfully" -ForegroundColor Green
    } elseif ($DryRun) {
        Write-Host "Step 2: Dry run mode - project file would be updated with version $newVersion" -ForegroundColor Yellow
    } else {
        Write-Host "Step 2: Skipping project file update (use -UpdateProject to enable)" -ForegroundColor Yellow
    }
    
    # Create git tag if requested
    if ($CreateTag -and -not $DryRun) {
        Write-Host "Step 3: Creating git tag..." -ForegroundColor Yellow
        
        $tagMessage = "Release version $newVersion"
        
        if ($ForceTag) {
            & "$scriptDir/create-git-tag.ps1" -Version $newVersion -TagMessage $tagMessage -Force
        } else {
            & "$scriptDir/create-git-tag.ps1" -Version $newVersion -TagMessage $tagMessage
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Git tag creation failed"
        }
        
        Write-Host "Git tag created successfully" -ForegroundColor Green
    } elseif ($CreateTag -and $DryRun) {
        Write-Host "Step 3: Dry run mode - git tag v$newVersion would be created" -ForegroundColor Yellow
    } else {
        Write-Host "Step 3: Skipping git tag creation (use -CreateTag to enable)" -ForegroundColor Yellow
    }
    
    # Output final results for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "current-version=$($jsonData.currentVersion)"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "next-version=$newVersion"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "increment-type=$incrementType"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "release-notes=$releaseNotes"
        Write-Host "Results written to GitHub Actions output" -ForegroundColor Green
    }
    
    Write-Host "=== Version Management Completed Successfully ===" -ForegroundColor Cyan
    exit 0
}
catch {
    Write-Error "Version management failed: $_"
    exit 1
}