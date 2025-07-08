# Scripts Directory

This directory contains administrative and setup scripts for the AKS Private repository.

## 🔐 Security Notice

**These scripts require elevated permissions and should only be run by repository administrators.**

## Scripts

### `setup-github-environments.sh`

**Purpose**: One-time setup of GitHub environments (dev, staging, prod)

**Requirements**:
- Repository admin permissions
- GitHub CLI (`gh`) installed and authenticated
- Run manually by administrator

**Usage**:
```bash
# From repository root
./scripts/setup-github-environments.sh
```

**Security Notes**:
- ⚠️ **ADMIN ONLY** - Requires repository admin permissions
- 🚫 **NOT for CI/CD** - Should never be run in automated workflows
- 🔒 **One-time use** - Only needed during initial repository setup
- 📋 **Audit trail** - Check git history to see when environments were created

**What it does**:
1. Verifies admin permissions
2. Creates three GitHub environments: `dev`, `staging`, `prod`
3. Configures basic protection rules
4. Provides next steps for manual secret configuration

## Best Practices

### ✅ DO:
- Run scripts manually with admin permissions
- Review script contents before execution
- Document when and why scripts were run
- Keep scripts in version control for reproducibility

### ❌ DON'T:
- Run admin scripts in CI/CD workflows
- Grant elevated permissions to regular workflows
- Execute scripts without understanding their purpose
- Share admin credentials or tokens

## Environment Setup Process

1. **Administrator runs**: `./scripts/setup-github-environments.sh`
2. **Manual configuration**: Add secrets via GitHub UI
3. **Verification**: Run workflow to verify setup
4. **Regular usage**: Standard workflows with minimal permissions

This follows the principle of **separation of concerns** and **least privilege**.
