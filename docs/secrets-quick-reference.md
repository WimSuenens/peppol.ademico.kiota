# GitHub Secrets Quick Reference

## Required Secret

| Secret Name | Purpose | Source |
|-------------|---------|--------|
| `NUGET_API_KEY` | Authenticate with nuget.org for package publishing | Generated from nuget.org API Keys page |

## Quick Setup

1. **Generate API Key**: nuget.org → Profile → API Keys → Create
2. **Configure Secret**: GitHub Repository → Settings → Secrets and variables → Actions → New repository secret
3. **Test**: Merge a PR to trigger the workflow

## Common Issues

| Error | Quick Fix |
|-------|-----------|
| 401 Unauthorized | Check API key validity and permissions |
| 403 Forbidden | Verify package ownership and API key scope |
| 409 Conflict | Version already exists - check version increment |
| Secret not found | Verify secret name is exactly `NUGET_API_KEY` |

## API Key Requirements

- **Scope**: "Push new packages and package versions"
- **Pattern**: `Peppol.Ademico.Kiota*`
- **Expiration**: 365 days (recommended)

## Security Notes

- API key is shown only once during creation
- Rotate keys annually
- Limit scope to specific packages
- Monitor publishing activity regularly