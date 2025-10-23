# Git Tagging Script
# This script creates git tags with new version numbers after successful publishing

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$TagMessage = "",
    
    [Parameter(Mandatory=$false)]
    [string]$CommitSha = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

# Function to validate version format
function Test-VersionFormat {
    param([string]$Version)
    
    # Support both standard semantic versions (x.y.z) and pre-release versions (x.y.z-prerelease)
    if ($Version -match '^\d+\.\d+\.\d+(-[\w\.-]+)?$') {
        return $true
    } else {
        return $false
    }
}

# Function to check if tag already exists
function Test-TagExists {
    param([string]$TagName)
    
    try {
        $existingTags = git tag -l $TagName
        return ($existingTags -eq $TagName)
    }
    catch {
        Write-Warning "Failed to check existing tags: $_"
        return $false
    }
}

# Function to validate git repository
function Test-GitRepository {
    try {
        $gitStatus = git status --porcelain 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Function to get current commit SHA
function Get-CurrentCommitSha {
    try {
        return (git rev-parse HEAD).Trim()
    }
    catch {
        throw "Failed to get current commit SHA: $_"
    }
}

# Function to create git tag
function New-GitTag {
    param(
        [string]$TagName,
        [string]$Message,
        [string]$CommitSha,
        [bool]$Force,
        [bool]$DryRun
    )
    
    try {
        # Build git tag command
        $gitArgs = @("tag")
        
        if ($Force) {
            $gitArgs += "-f"
        }
        
        if ($Message) {
            $gitArgs += "-a"
            $gitArgs += $TagName
            $gitArgs += "-m"
            $gitArgs += $Message
        } else {
            $gitArgs += $TagName
        }
        
        if ($CommitSha) {
            $gitArgs += $CommitSha
        }
        
        if ($DryRun) {
            Write-Host "DRY RUN: Would execute: git $($gitArgs -join ' ')" -ForegroundColor Yellow
            return $true
        }
        
        # Execute git tag command
        Write-Host "Creating git tag: $TagName" -ForegroundColor Green
        & git @gitArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Git tag creation failed with exit code $LASTEXITCODE"
        }
        
        Write-Host "Git tag '$TagName' created successfully" -ForegroundColor Green
        return $true
    }
    catch {
        throw "Failed to create git tag: $_"
    }
}

# Function to push tag to remote
function Push-GitTag {
    param(
        [string]$TagName,
        [bool]$Force,
        [bool]$DryRun
    )
    
    try {
        # Build git push command
        $gitArgs = @("push", "origin", $TagName)
        
        if ($Force) {
            $gitArgs += "--force"
        }
        
        if ($DryRun) {
            Write-Host "DRY RUN: Would execute: git $($gitArgs -join ' ')" -ForegroundColor Yellow
            return $true
        }
        
        # Execute git push command
        Write-Host "Pushing git tag to remote: $TagName" -ForegroundColor Green
        & git @gitArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Git tag push failed with exit code $LASTEXITCODE"
        }
        
        Write-Host "Git tag '$TagName' pushed to remote successfully" -ForegroundColor Green
        return $true
    }
    catch {
        throw "Failed to push git tag: $_"
    }
}

# Main execution
try {
    Write-Host "=== Git Tagging Script ===" -ForegroundColor Cyan
    Write-Host "Version: $Version" -ForegroundColor Gray
    Write-Host "Tag Message: $TagMessage" -ForegroundColor Gray
    Write-Host "Commit SHA: $CommitSha" -ForegroundColor Gray
    Write-Host "Force: $Force" -ForegroundColor Gray
    Write-Host "Dry Run: $DryRun" -ForegroundColor Gray
    
    # Validate version format
    if (-not (Test-VersionFormat -Version $Version)) {
        throw "Invalid version format. Expected semantic version (x.y.z): $Version"
    }
    
    # Validate git repository
    if (-not (Test-GitRepository)) {
        throw "Not in a git repository or git is not available"
    }
    
    # Create tag name with 'v' prefix
    $tagName = "v$Version"
    
    # Check if tag already exists
    $tagExists = Test-TagExists -TagName $tagName
    if ($tagExists -and -not $Force) {
        throw "Tag '$tagName' already exists. Use -Force to overwrite."
    }
    
    if ($tagExists -and $Force) {
        Write-Warning "Tag '$tagName' already exists and will be overwritten"
    }
    
    # Get commit SHA if not provided
    if (-not $CommitSha) {
        $CommitSha = Get-CurrentCommitSha
        Write-Host "Using current commit SHA: $CommitSha" -ForegroundColor Gray
    }
    
    # Generate tag message if not provided
    if (-not $TagMessage) {
        $TagMessage = "Release version $Version"
    }
    
    # Create the git tag
    $tagCreated = New-GitTag -TagName $tagName -Message $TagMessage -CommitSha $CommitSha -Force $Force -DryRun $DryRun
    
    if ($tagCreated) {
        # Push tag to remote (only if not dry run and we have remote)
        try {
            $remoteExists = (git remote 2>$null) -ne $null
            if ($remoteExists -and -not $DryRun) {
                Push-GitTag -TagName $tagName -Force $Force -DryRun $DryRun
            } elseif ($DryRun) {
                Write-Host "DRY RUN: Would push tag to remote if remote exists" -ForegroundColor Yellow
            } else {
                Write-Host "No remote repository configured, skipping tag push" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Warning "Failed to push tag to remote: $_"
            Write-Host "Tag created locally but not pushed to remote" -ForegroundColor Yellow
        }
    }
    
    # Output results for GitHub Actions
    if ($env:GITHUB_OUTPUT) {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "tag-name=$tagName"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "tag-created=$tagCreated"
        Write-Host "Tag information written to GitHub Actions output" -ForegroundColor Green
    }
    
    Write-Host "=== Git Tagging Completed Successfully ===" -ForegroundColor Cyan
    exit 0
}
catch {
    Write-Error "Git tagging failed: $_"
    exit 1
}