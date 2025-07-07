# Azure Storage Authentication Monitoring Guide

## Overview
Azure Monitor diagnostic logging for storage accounts can capture detailed authentication and authorization events to help troubleshoot access issues.

## What Azure Monitor Captures

### ✅ **Authentication Events Logged:**
- **401 Unauthorized** - Invalid or missing authentication tokens
- **403 Forbidden** - Valid authentication but insufficient permissions  
- **Authentication Type** - Shows if using Azure AD, SAS, or account keys
- **Caller IP Address** - Identifies the source of requests
- **Requester Object ID** - Shows which service principal made the request
- **Operation Names** - Specific storage operations attempted

### ✅ **Specific Issues Detected:**
- **RBAC Permission Gaps** - When service principal lacks required roles
- **Token Expiration** - When OIDC tokens expire during operations
- **Scope Mismatches** - When permissions are assigned to wrong resource scope
- **Authentication Method Conflicts** - When storage account settings conflict with auth method

## Useful Queries for Terraform Backend Issues

### 🔍 **Authentication Failures**
```kusto
StorageBlobLogs
| where TimeGenerated > ago(2h)
| where StatusCode in (401, 403)
| project TimeGenerated, StatusCode, StatusText, OperationName, CallerIpAddress, AuthenticationType, RequesterObjectId
| order by TimeGenerated desc
```

### 🔍 **Terraform-Specific Operations**
```kusto
StorageBlobLogs
| where TimeGenerated > ago(2h)
| where OperationName contains "List" or OperationName contains "Get" or OperationName contains "Put"
| where UserAgentHeader contains "terraform" or UserAgentHeader contains "Go-http-client"
| project TimeGenerated, StatusCode, OperationName, Uri, AuthenticationType, StatusText
| order by TimeGenerated desc
```

### 🔍 **Permission-Related Errors**
```kusto
StorageBlobLogs
| where TimeGenerated > ago(2h)
| where StatusCode == 403
| where StatusText contains "insufficient" or StatusText contains "not authorized"
| project TimeGenerated, OperationName, Uri, RequesterObjectId, StatusText
```

## Common Error Patterns

| Status Code | Common Cause | Solution |
|-------------|--------------|----------|
| **403** with "AuthorizationFailure" | Missing Storage Blob Data Owner role | Add proper RBAC role assignment |
| **403** with "Shared Key access is disabled" | Using account keys when disabled | Use Azure AD auth (`use_azuread_auth = true`) |
| **401** with "Authentication failed" | Invalid or expired token | Check OIDC token generation and service principal config |
| **403** with "Insufficient privileges" | Wrong permission scope | Assign roles at storage account level, not subscription |

## Setup Commands

The backend setup script automatically enables these diagnostic settings:

```bash
# Storage Account Diagnostics
az monitor diagnostic-settings create \
    --name "terraform-backend-diagnostics" \
    --resource "<storage-account-resource-id>" \
    --workspace "<log-analytics-workspace-id>" \
    --logs '[{"category": "StorageRead", "enabled": true}, ...]'

# Blob Service Diagnostics  
az monitor diagnostic-settings create \
    --name "terraform-backend-blob-diagnostics" \
    --resource "<storage-account-blob-service-resource-id>" \
    --workspace "<log-analytics-workspace-id>" \
    --logs '[{"category": "StorageRead", "enabled": true}, ...]'
```

## Monitoring Best Practices

1. **Enable diagnostics early** - Set up before encountering issues
2. **Monitor authentication patterns** - Look for consistent failure patterns
3. **Check permission propagation** - RBAC assignments can take 5-10 minutes
4. **Correlate with Azure AD logs** - Cross-reference with sign-in logs
5. **Review service principal configuration** - Verify federated credentials are correct

## Quick Troubleshooting Checklist

When you encounter 403 errors:

1. ✅ **Check RBAC assignments** - Verify service principal has required roles
2. ✅ **Verify token validity** - Ensure OIDC tokens are being generated  
3. ✅ **Check storage account settings** - Confirm shared key access is disabled
4. ✅ **Review diagnostic logs** - Look for specific error messages in Azure Monitor
5. ✅ **Wait for propagation** - RBAC changes can take up to 10 minutes
6. ✅ **Test with Azure CLI** - Verify access using `az storage blob list`

This monitoring setup provides comprehensive visibility into authentication flows and helps quickly identify the root cause of access issues.
