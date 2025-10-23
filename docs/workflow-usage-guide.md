# NuGet CI/CD Workflow Usage Guide

This guide explains how to use the automated NuGet publishing workflow for the Peppol.Ademico.Kiota package. The workflow automatically builds, versions, and publishes packages when pull requests are merged to the main branch.

## Overview

The CI/CD pipeline is triggered automatically when:
- A pull request is **merged** (not just closed) into the `main` branch
- Changes are made to relevant source files (see [Trigger Conditions](#trigger-conditions))

The workflow performs the following steps:
1. **Build Validation**: Restores dependencies, builds the project, and runs tests
2. **Version Management**: Calculates the next version based on commit messages and PR labels
3. **Package Creation**: Creates the NuGet package with updated metadata
4. **Quality Gates**: Validates package contents and metadata
5. **Publishing**: Publishes the package to nuget.org with authentication
6. **Verification**: Confirms successful publication and creates git tags

## Trigger Conditions

### Automatic Triggers

The workflow triggers automatically when:

```yaml
# Pull request merged to main branch
on:
  pull_request:
    types: [closed]
    branches: [main]
    paths:
      - 'src/**'
      - '**/*.csproj'
      - '**/*.sln'
      - '**/*.slnx'
```

**Required Conditions:**
- Pull request must be **merged** (not just closed without merging)
- Target branch must be `main`
- Changes must include files in the monitored paths

**Monitored File Paths:**
- `src/**` - All source code files
- `**/*.csproj` - Project files
- `**/*.sln` - Solution files  
- `**/*.slnx` - Solution extension files

### Files That Don't Trigger Workflow

Changes to these files alone will **NOT** trigger the workflow:
- Documentation files (`*.md`, `docs/**`)
- Configuration files (`.gitignore`, `.editorconfig`)
- GitHub workflow files (`.github/**`)
- Test-only changes outside the `src/` directory

## How to Trigger a Release

### Step 1: Create a Feature Branch

```bash
# Create and switch to a new feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Commit your changes
git add .
git commit -m "feat: add new functionality"
git push origin feature/your-feature-name
```

### Step 2: Create a Pull Request

1. **Navigate to GitHub Repository**
   - Go to your repository on GitHub
   - Click "Compare & pull request" or create a new PR

2. **Fill PR Information**
   - **Title**: Descriptive title of your changes
   - **Description**: Detailed description of what changed
   - **Labels**: Add appropriate labels for version increment (see [Version Increment Rules](#version-increment-rules))

3. **Review and Approval**
   - Request reviews from team members
   - Address any feedback
   - Ensure all checks pass

### Step 3: Merge the Pull Request

1. **Merge Options**
   - **Merge commit**: Creates a merge commit (recommended)
   - **Squash and merge**: Combines all commits into one
   - **Rebase and merge**: Replays commits without merge commit

2. **Merge Process**
   - Click "Merge pull request"
   - Confirm the merge
   - The workflow will trigger automatically

### Step 4: Monitor Workflow Execution

1. **Navigate to Actions Tab**
   - Go to the "Actions" tab in your repository
   - Find the "Publish NuGet Package" workflow run

2. **Monitor Progress**
   - Watch the workflow steps execute
   - Check for any failures or warnings
   - Review the workflow summary

## Version Increment Rules

The workflow automatically calculates the next version based on commit messages and pull request labels following semantic versioning (SemVer).

### Current Version Format

```
Major.Minor.Patch (e.g., 1.2.3)
```

### Increment Rules

#### Patch Version Increment (Default)

**When**: No special commit messages or labels are detected

**Examples**:
- `fix: resolve authentication issue`
- `docs: update README`
- `refactor: improve code structure`

**Result**: `1.2.3` → `1.2.4`

#### Minor Version Increment

**Triggered by**:
- Commit messages starting with `feat:`
- Pull request labels: `enhancement`, `feature`

**Examples**:
- `feat: add new API endpoint`
- `feat(auth): implement OAuth2 support`
- PR labeled with `enhancement`

**Result**: `1.2.3` → `1.3.0`

#### Major Version Increment

**Triggered by**:
- Commit messages containing `BREAKING CHANGE:`
- Pull request labels: `breaking-change`, `major`

**Examples**:
- `feat!: redesign API interface`
- `feat: add new feature\n\nBREAKING CHANGE: removes old API`
- PR labeled with `breaking-change`

**Result**: `1.2.3` → `2.0.0`

### Version Calculation Process

1. **Read Current Version**: Extract version from `.csproj` file
2. **Analyze Commits**: Scan commit messages since last release
3. **Check PR Labels**: Review labels on the merged pull request
4. **Determine Increment**: Apply highest priority increment rule
5. **Update Project**: Modify `.csproj` with new version
6. **Create Tag**: Generate git tag after successful publication

## Release Scenarios and Examples

### Scenario 1: Bug Fix Release

**Situation**: Fix a critical bug in authentication

**Steps**:
```bash
# Create feature branch
git checkout -b fix/auth-bug

# Make changes and commit
git commit -m "fix: resolve token expiration issue"

# Push and create PR
git push origin fix/auth-bug
```

**PR Details**:
- Title: "Fix token expiration issue"
- Labels: None (default patch increment)

**Expected Result**:
- Version: `1.2.3` → `1.2.4`
- Package: `Peppol.Ademico.Kiota.1.2.4.nupkg`
- Git tag: `v1.2.4`

### Scenario 2: New Feature Release

**Situation**: Add new invoice validation functionality

**Steps**:
```bash
# Create feature branch
git checkout -b feature/invoice-validation

# Make changes and commit
git commit -m "feat: add invoice validation API"

# Push and create PR
git push origin feature/invoice-validation
```

**PR Details**:
- Title: "Add invoice validation API"
- Labels: `enhancement` or `feature`

**Expected Result**:
- Version: `1.2.3` → `1.3.0`
- Package: `Peppol.Ademico.Kiota.1.3.0.nupkg`
- Git tag: `v1.3.0`

### Scenario 3: Breaking Change Release

**Situation**: Redesign API to improve performance (breaking existing code)

**Steps**:
```bash
# Create feature branch
git checkout -b feature/api-redesign

# Make changes and commit
git commit -m "feat!: redesign API for better performance

BREAKING CHANGE: The authentication method has changed.
Old method: client.Authenticate(username, password)
New method: client.Authenticate(new AuthRequest(username, password))"

# Push and create PR
git push origin feature/api-redesign
```

**PR Details**:
- Title: "Redesign API for better performance"
- Labels: `breaking-change`

**Expected Result**:
- Version: `1.2.3` → `2.0.0`
- Package: `Peppol.Ademico.Kiota.2.0.0.nupkg`
- Git tag: `v2.0.0`

### Scenario 4: Multiple Changes in One PR

**Situation**: PR contains both bug fixes and new features

**Steps**:
```bash
# Create feature branch
git checkout -b feature/mixed-changes

# Make multiple commits
git commit -m "fix: resolve connection timeout"
git commit -m "feat: add retry mechanism"
git commit -m "docs: update API documentation"

# Push and create PR
git push origin feature/mixed-changes
```

**PR Details**:
- Title: "Fix timeouts and add retry mechanism"
- Labels: `enhancement`

**Expected Result**:
- Version: `1.2.3` → `1.3.0` (highest increment wins)
- Reason: `feat:` commit triggers minor increment

### Scenario 5: Documentation-Only Changes

**Situation**: Update README and documentation

**Steps**:
```bash
# Create feature branch
git checkout -b docs/update-readme

# Make changes to documentation only
git commit -m "docs: update installation instructions"

# Push and create PR
git push origin docs/update-readme
```

**Expected Result**:
- **Workflow does NOT trigger** (no source code changes)
- No new package version
- No git tag created

## Commit Message Conventions

### Recommended Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Common Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
# Simple bug fix
git commit -m "fix: resolve null reference exception"

# New feature with scope
git commit -m "feat(auth): implement JWT token validation"

# Breaking change
git commit -m "feat!: redesign configuration API

BREAKING CHANGE: Configuration.Load() now returns ConfigResult instead of Config"

# Multiple paragraph description
git commit -m "feat: add invoice processing pipeline

This commit introduces a new pipeline for processing invoices
with support for multiple formats and validation rules.

The pipeline includes:
- Format detection
- Schema validation  
- Business rule validation
- Error reporting"
```

## Pull Request Labels

### Version Control Labels

| Label | Effect | Description |
|-------|--------|-------------|
| `patch` | Patch increment | Bug fixes, minor improvements |
| `enhancement` | Minor increment | New features, enhancements |
| `feature` | Minor increment | New functionality |
| `breaking-change` | Major increment | Breaking API changes |
| `major` | Major increment | Major version bump |

### Other Useful Labels

| Label | Purpose |
|-------|---------|
| `bug` | Indicates bug fix |
| `documentation` | Documentation changes |
| `dependencies` | Dependency updates |
| `security` | Security-related changes |
| `performance` | Performance improvements |

## Monitoring and Troubleshooting

### Workflow Status

**Check Workflow Status**:
1. Go to repository "Actions" tab
2. Find "Publish NuGet Package" workflow
3. Click on the specific run to see details

**Workflow Indicators**:
- ✅ **Success**: Package published successfully
- ❌ **Failure**: Workflow failed (check logs)
- 🟡 **In Progress**: Workflow currently running
- ⏸️ **Cancelled**: Workflow was cancelled

### Common Issues and Solutions

#### Issue: Workflow Doesn't Trigger

**Possible Causes**:
- PR was closed without merging
- No changes to monitored file paths
- Target branch is not `main`

**Solutions**:
- Ensure PR is merged, not just closed
- Make changes to files in `src/` directory
- Check that target branch is `main`

#### Issue: Version Already Exists

**Error Message**:
```
error: Response status code does not indicate success: 409 (Conflict)
```

**Solutions**:
- Check existing versions on nuget.org
- Manually increment version in `.csproj` if needed
- Ensure version calculation logic is working correctly

#### Issue: Authentication Failure

**Error Message**:
```
error: Response status code does not indicate success: 401 (Unauthorized)
```

**Solutions**:
- Verify `NUGET_API_KEY` secret is configured
- Check API key permissions on nuget.org
- Ensure API key hasn't expired

#### Issue: Build or Test Failures

**Solutions**:
- Fix compilation errors in the code
- Ensure all tests pass locally
- Check for missing dependencies
- Review build logs for specific errors

### Getting Help

**Workflow Logs**:
- Detailed logs available in GitHub Actions tab
- Each step shows execution details and errors
- Download logs for offline analysis

**Debug Mode**:
Add this secret to enable verbose logging:
- Name: `ACTIONS_STEP_DEBUG`
- Value: `true`

**Manual Testing**:
Test locally before creating PR:
```bash
# Restore and build
dotnet restore src/Peppol.Ademico.Kiota/Peppol.Ademico.Kiota.csproj
dotnet build src/Peppol.Ademico.Kiota/Peppol.Ademico.Kiota.csproj --configuration Release

# Run tests
dotnet test src/Peppol.Ademico.Kiota/Peppol.Ademico.Kiota.csproj --configuration Release

# Create package
dotnet pack src/Peppol.Ademico.Kiota/Peppol.Ademico.Kiota.csproj --configuration Release
```

## Best Practices

### Development Workflow

1. **Feature Branches**: Always work in feature branches
2. **Small PRs**: Keep pull requests focused and small
3. **Clear Commits**: Use descriptive commit messages
4. **Test Locally**: Test changes before creating PR
5. **Review Process**: Always get code reviews

### Version Management

1. **Semantic Versioning**: Follow SemVer principles
2. **Breaking Changes**: Clearly document breaking changes
3. **Release Notes**: Use descriptive commit messages for auto-generated notes
4. **Version Planning**: Plan major versions carefully

### Quality Assurance

1. **Test Coverage**: Ensure adequate test coverage
2. **Build Validation**: Fix all build warnings
3. **Documentation**: Update documentation with changes
4. **Backward Compatibility**: Maintain compatibility when possible

### Security

1. **Secret Management**: Never commit API keys or secrets
2. **Permissions**: Use least-privilege access
3. **Regular Updates**: Rotate API keys periodically
4. **Audit Trail**: Monitor package publishing activity

## Workflow Customization

### Modifying Trigger Conditions

To change when the workflow triggers, edit `.github/workflows/publish-nuget.yml`:

```yaml
# Example: Also trigger on direct pushes to main
on:
  pull_request:
    types: [closed]
    branches: [main]
    paths: ['src/**', '**/*.csproj', '**/*.sln', '**/*.slnx']
  push:
    branches: [main]
    paths: ['src/**', '**/*.csproj', '**/*.sln', '**/*.slnx']
```

### Adding Additional Quality Gates

```yaml
# Example: Add code coverage requirements
- name: Check code coverage
  run: |
    dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage
    # Add coverage validation logic here
```

### Custom Version Calculation

The version calculation logic can be customized by modifying the version management steps in the workflow.

## Next Steps

After setting up the workflow:

1. **Test the Pipeline**: Create a test PR to verify workflow execution
2. **Monitor First Release**: Watch the first automated release carefully
3. **Team Training**: Ensure team understands the process
4. **Documentation**: Keep this guide updated with any customizations
5. **Feedback Loop**: Gather feedback and improve the process

For additional help or questions, refer to:
- [GitHub Secrets Setup Guide](./github-secrets-setup.md)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [NuGet Publishing Documentation](https://docs.microsoft.com/en-us/nuget/nuget-org/publish-a-package)