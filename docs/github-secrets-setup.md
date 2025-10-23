# GitHub Secrets Configuration Guide

This guide provides step-by-step instructions for configuring GitHub Secrets required for the automated NuGet publishing pipeline.

## Required Secrets

### NUGET_API_KEY

The `NUGET_API_KEY` secret is required to authenticate with nuget.org for package publishing.

## Setup Instructions

### Step 1: Generate NuGet API Key

1. **Sign in to nuget.org**
   - Go to [nuget.org](https://www.nuget.org)
   - Sign in with your Microsoft account or create a new account

2. **Navigate to API Keys**
   - Click on your username in the top-right corner
   - Select "API Keys" from the dropdown menu

3. **Create New API Key**
   - Click "Create" button
   - Fill in the following details:
     - **Key Name**: `GitHub-Actions-Peppol-Ademico-Kiota` (or similar descriptive name)
     - **Package Owner**: Select your account or organization
     - **Scopes**: Select "Push new packages and package versions"
     - **Packages**: 
       - Select "Packages and versions matching glob pattern"
       - Enter pattern: `Peppol.Ademico.Kiota*`
     - **Expiration**: Set to 365 days (recommended) or custom duration

4. **Copy the API Key**
   - Click "Create" to generate the key
   - **IMPORTANT**: Copy the API key immediately - it will only be shown once
   - Store it securely (you'll need it in the next step)

### Step 2: Configure GitHub Repository Secret

1. **Navigate to Repository Settings**
   - Go to your GitHub repository
   - Click on "Settings" tab
   - In the left sidebar, click "Secrets and variables" → "Actions"

2. **Add Repository Secret**
   - Click "New repository secret"
   - **Name**: Enter `NUGET_API_KEY` (exactly as shown)
   - **Secret**: Paste the API key you copied from nuget.org
   - Click "Add secret"

3. **Verify Secret Configuration**
   - The secret should now appear in the list as `NUGET_API_KEY`
   - The value will be hidden for security

## Required Permissions and Access Levels

### Repository Permissions

The following permissions are required for the GitHub Actions workflow:

- **Contents**: Write access (for creating git tags)
- **Pull Requests**: Read access (for accessing PR information)
- **Actions**: Write access (for workflow execution)

### NuGet API Key Permissions

The NuGet API key must have the following scopes:

- **Push new packages and package versions**: Required for publishing
- **Package scope**: Limited to `Peppol.Ademico.Kiota*` pattern for security

### User Access Requirements

- **Repository**: Must be a repository owner or have admin access to configure secrets
- **NuGet.org**: Must be the package owner or have push permissions for the package

## Security Best Practices

### API Key Security

1. **Scope Limitation**: Always limit API key scope to specific packages
2. **Expiration**: Set reasonable expiration dates (recommended: 1 year)
3. **Regular Rotation**: Rotate API keys periodically
4. **Access Monitoring**: Monitor package publishing activity

### GitHub Secrets Security

1. **Least Privilege**: Only grant necessary repository permissions
2. **Access Control**: Limit repository admin access to trusted users
3. **Audit Trail**: Monitor secret usage in workflow runs
4. **Environment Separation**: Use different secrets for different environments

## Troubleshooting Guide

### Common Authentication Issues

#### Issue: "401 Unauthorized" Error

**Symptoms:**
```
error: Response status code does not indicate success: 401 (Unauthorized)
```

**Possible Causes:**
1. Invalid or expired NuGet API key
2. API key doesn't have push permissions for the package
3. Secret name mismatch in GitHub

**Solutions:**
1. **Verify API Key Validity**
   - Check if the API key has expired on nuget.org
   - Regenerate the API key if necessary

2. **Check API Key Permissions**
   - Ensure the API key has "Push new packages and package versions" scope
   - Verify the package pattern includes your package name

3. **Verify GitHub Secret Configuration**
   - Confirm the secret name is exactly `NUGET_API_KEY`
   - Re-add the secret with the correct API key value

#### Issue: "403 Forbidden" Error

**Symptoms:**
```
error: Response status code does not indicate success: 403 (Forbidden)
```

**Possible Causes:**
1. API key doesn't have permissions for the specific package
2. Package ownership issues
3. Package ID conflicts

**Solutions:**
1. **Check Package Ownership**
   - Verify you own the package on nuget.org
   - If it's a new package, ensure the package ID is available

2. **Review API Key Scope**
   - Ensure the API key scope includes your package
   - Update the glob pattern if necessary

3. **Verify Package ID**
   - Check that the package ID in .csproj matches the intended package name
   - Ensure no typos in the package identifier

#### Issue: "409 Conflict" Error

**Symptoms:**
```
error: Response status code does not indicate success: 409 (Conflict)
```

**Possible Causes:**
1. Package version already exists on nuget.org
2. Version increment logic failure

**Solutions:**
1. **Check Existing Versions**
   - Visit your package page on nuget.org
   - Verify the version you're trying to publish doesn't already exist

2. **Review Version Logic**
   - Check the workflow logs for version calculation
   - Ensure the version increment logic is working correctly

#### Issue: Secret Not Found

**Symptoms:**
```
Error: Secret NUGET_API_KEY not found
```

**Solutions:**
1. **Verify Secret Name**
   - Ensure the secret is named exactly `NUGET_API_KEY`
   - Check for typos or extra spaces

2. **Check Secret Scope**
   - Ensure the secret is configured at the repository level
   - Verify you have the correct repository selected

3. **Re-add Secret**
   - Delete and re-create the secret if necessary
   - Ensure you have admin permissions on the repository

### Workflow Debugging

#### Enable Debug Logging

Add the following secrets to enable detailed workflow logging:

- **Name**: `ACTIONS_STEP_DEBUG`
- **Value**: `true`

#### Check Workflow Permissions

Ensure the workflow has the necessary permissions in the YAML file:

```yaml
permissions:
  contents: write
  pull-requests: read
  actions: write
```

### Getting Help

If you continue to experience issues:

1. **Check Workflow Logs**: Review the detailed logs in the GitHub Actions tab
2. **Verify Requirements**: Ensure all requirements from the design document are met
3. **Test Manually**: Try publishing manually using `dotnet nuget push` to isolate issues
4. **Contact Support**: Reach out to NuGet support for API key or publishing issues

## Validation Checklist

Before running the workflow, verify:

- [ ] NuGet API key is generated with correct permissions
- [ ] GitHub secret `NUGET_API_KEY` is configured
- [ ] Repository has necessary permissions
- [ ] Package ownership is confirmed on nuget.org
- [ ] Workflow file references the correct secret name
- [ ] API key expiration date is noted for future rotation

## Next Steps

After completing the secret configuration:

1. Test the workflow by merging a pull request
2. Monitor the workflow execution in the Actions tab
3. Verify successful package publication on nuget.org
4. Set up monitoring for API key expiration