# Version Management Scripts

This directory contains PowerShell scripts for automated version management in the CI/CD pipeline.

## Scripts Overview

### 1. version-calculator.ps1
Calculates the next semantic version based on commit messages and PR labels.

**Usage:**
```powershell
./version-calculator.ps1 -ProjectPath "path/to/project.csproj" [-CommitMessages "commit messages"] [-PrLabels "labels"] [-DefaultIncrement "patch"]
```

**Parameters:**
- `ProjectPath` (required): Path to the .csproj file
- `CommitMessages` (optional): Commit messages to analyze for version increment
- `PrLabels` (optional): PR labels to analyze for version increment
- `DefaultIncrement` (optional): Default increment type (patch, minor, major). Default: "patch"

**Version Increment Rules:**
- **Major**: `BREAKING CHANGE:` in commit messages OR `breaking-change` label
- **Minor**: `feat:` in commit messages OR `enhancement` label  
- **Patch**: `fix:`, `chore:`, `docs:` in commit messages OR default increment

**Output:**
- Console output with version information
- GitHub Actions output variables (if `GITHUB_OUTPUT` env var is set)
- JSON output for programmatic consumption

### 2. update-project-version.ps1
Updates version properties in the .csproj file.

**Usage:**
```powershell
./update-project-version.ps1 -ProjectPath "path/to/project.csproj" -NewVersion "1.2.3" [-ReleaseNotes "notes"]
```

**Parameters:**
- `ProjectPath` (required): Path to the .csproj file
- `NewVersion` (required): New semantic version (x.y.z format)
- `ReleaseNotes` (optional): Release notes to update in PackageReleaseNotes

**Updates:**
- `<Version>` property
- `<AssemblyVersion>` property (if exists)
- `<FileVersion>` property (if exists)
- `<PackageReleaseNotes>` property (if exists and ReleaseNotes provided)

### 3. manage-version.ps1
Wrapper script that combines version calculation and project file updates.

**Usage:**
```powershell
./manage-version.ps1 -ProjectPath "path/to/project.csproj" [-CommitMessages "messages"] [-PrLabels "labels"] [-UpdateProject] [-DryRun]
```

**Parameters:**
- `ProjectPath` (required): Path to the .csproj file
- `CommitMessages` (optional): Commit messages to analyze
- `PrLabels` (optional): PR labels to analyze
- `DefaultIncrement` (optional): Default increment type. Default: "patch"
- `UpdateProject` (switch): Actually update the project file
- `DryRun` (switch): Show what would be done without making changes

## Examples

### Calculate next version only
```powershell
./version-calculator.ps1 -ProjectPath "src/MyProject/MyProject.csproj" -CommitMessages "feat: add new feature"
```

### Update project with new version
```powershell
./manage-version.ps1 -ProjectPath "src/MyProject/MyProject.csproj" -CommitMessages "fix: resolve bug" -UpdateProject
```

### Dry run to see what would happen
```powershell
./manage-version.ps1 -ProjectPath "src/MyProject/MyProject.csproj" -CommitMessages "feat: BREAKING CHANGE: remove old API" -DryRun
```

### Use with PR labels
```powershell
./manage-version.ps1 -ProjectPath "src/MyProject/MyProject.csproj" -PrLabels "enhancement" -UpdateProject
```

## GitHub Actions Integration

These scripts are designed to work with GitHub Actions. When `GITHUB_OUTPUT` environment variable is set, the scripts will write output variables that can be used in subsequent workflow steps:

- `current-version`: The current version from the project file
- `next-version`: The calculated next version
- `increment-type`: The type of increment (major, minor, patch)
- `release-notes`: Generated release notes

Example GitHub Actions usage:
```yaml
- name: Calculate Version
  id: version
  run: |
    pwsh .github/scripts/manage-version.ps1 -ProjectPath "src/MyProject/MyProject.csproj" -CommitMessages "${{ github.event.commits[0].message }}" -UpdateProject

- name: Use Version
  run: |
    echo "New version: ${{ steps.version.outputs.next-version }}"
```

## Requirements

- PowerShell Core (pwsh) 6.0 or later
- .NET project with semantic versioning in .csproj file
- Valid XML structure in .csproj file

## Error Handling

All scripts include comprehensive error handling and will:
- Validate input parameters
- Check file existence and accessibility
- Validate version format
- Provide clear error messages
- Exit with appropriate exit codes (0 = success, 1 = error)