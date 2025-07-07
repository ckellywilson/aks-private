# 🚨 Service Principal Permission Issue - SOLUTION GUIDE

## 📋 **Issue Summary**

The Terraform backend setup is failing with **403 Authorization errors** because the service principal lacks sufficient permissions to:

1. **Assign roles** to itself (missing `User Access Administrator`)  
2. **Access Azure Storage** for Terraform state (missing `Storage Blob Data Owner`)
3. **Create storage containers** and manage blob data

## 🔍 **Diagnostic Results**

Based on the comprehensive diagnostic workflow, here's what we found:

### ✅ **What Works:**
- OIDC authentication is successful
- Service principal has `Contributor` role at subscription level
- Azure CLI access and basic operations work

### ❌ **What's Missing:**
- **`User Access Administrator`** role (required for `Microsoft.Authorization/roleAssignments/write`)
- **`Storage Blob Data Owner`** role (required for blob operations)
- **Proper storage account permissions** for Terraform backend access

## 🛠️ **SOLUTION - Choose Option 1 OR 2**

### **Option 1: Automated Fix Script (Recommended)**

Run the automated permission fix script with an account that has Owner or User Access Administrator privileges:

```bash
# Set environment variables
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_CLIENT_ID="your-service-principal-client-id"
export ENVIRONMENT="dev"

# Run the fix script
./scripts/fix-service-principal-permissions.sh
```

### **Option 2: Manual Azure CLI Commands**

If you prefer manual setup, run these commands with elevated privileges:

```bash
# 1. Grant User Access Administrator (required for role assignments)
az role assignment create \
  --role "User Access Administrator" \
  --assignee "your-service-principal-client-id" \
  --scope "/subscriptions/your-subscription-id"

# 2. Verify Contributor role exists (should already exist)
az role assignment list \
  --assignee "your-service-principal-client-id" \
  --role "Contributor" \
  --scope "/subscriptions/your-subscription-id"

# 3. Grant storage permissions (run after storage account exists)
STORAGE_ID=$(az storage account show \
  --name "staksdevcus001tfstate" \
  --resource-group "rg-terraform-state-dev-cus-001" \
  --query id -o tsv)

az role assignment create \
  --role "Storage Blob Data Owner" \
  --assignee "your-service-principal-client-id" \
  --scope "$STORAGE_ID"

# 4. Update storage network rules if needed
az storage account update \
  --name "staksdevcus001tfstate" \
  --resource-group "rg-terraform-state-dev-cus-001" \
  --default-action Allow
```

## 🚀 **Testing the Fix**

### 1. **Wait for Role Propagation**
```bash
# Wait 5-10 minutes for Azure AD to propagate role assignments
```

### 2. **Re-run Backend Setup**
```bash
gh workflow run "🔧 Setup Terraform Backend" --field environment=dev
```

### 3. **Monitor Progress**
```bash
# Check workflow status
gh run list --workflow="terraform-backend-setup.yml" --limit 5

# View logs if needed
gh run view [RUN_ID] --log
```

### 4. **Verify Success**
The backend setup should now complete successfully with:
- ✅ Storage account created/updated
- ✅ Storage container created  
- ✅ Role assignments completed
- ✅ Terraform initialization successful

## 🔍 **Troubleshooting**

### **If Issues Persist:**

1. **Run Diagnostic Again:**
   ```bash
   gh workflow run "🔍 Diagnose Service Principal Permissions" --field environment=dev
   ```

2. **Check Azure Monitor Logs:**
   ```bash
   # Use KQL queries from .github/AUTHENTICATION-MONITORING.md
   # Look for 403 errors in StorageBlobLogs
   ```

3. **Verify Role Assignments:**
   ```bash
   az role assignment list \
     --assignee "your-service-principal-client-id" \
     --output table
   ```

### **Common Solutions:**

- **Still getting 403?** → Check storage account network rules
- **Role assignment errors?** → Verify User Access Administrator role
- **Container creation fails?** → Check Storage Blob Data Owner permissions
- **Terraform init fails?** → Verify `use_azuread_auth = true` in backend config

## 📊 **Monitoring & Validation**

### **Azure Monitor Queries**
Use these KQL queries in Azure Monitor to track authentication events:

```kusto
// Check for 403 errors in storage
StorageBlobLogs
| where TimeGenerated > ago(2h)
| where StatusCode == 403
| project TimeGenerated, OperationName, Uri, RequesterObjectId, StatusText
```

### **Validation Checklist**
- [ ] Service principal has `User Access Administrator` role
- [ ] Service principal has `Contributor` role  
- [ ] Service principal has `Storage Blob Data Owner` on storage account
- [ ] Storage account network rules allow access
- [ ] Terraform backend config uses `use_azuread_auth = true`
- [ ] Backend setup workflow completes successfully
- [ ] Terraform init works without 403 errors

## 🎯 **Root Cause Explanation**

The 403 errors occurred because:

1. **GitHub Actions workflow** uses OIDC to authenticate as service principal
2. **Service principal** tries to assign storage roles to itself
3. **Azure RBAC** requires `User Access Administrator` permission for role assignments
4. **Without this permission**, all role assignment operations fail with 403
5. **Terraform backend access** also requires storage blob permissions

This is a common pattern in Infrastructure as Code where the automation needs to bootstrap its own permissions.

## 📚 **Related Documentation**

- [Azure RBAC Built-in Roles](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Azure Storage Authentication](https://docs.microsoft.com/azure/storage/common/storage-auth)
- [Terraform Azure Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [GitHub Actions OIDC](https://docs.github.com/actions/deployment/security/configuring-openid-connect-in-azure)

---
**Status:** Ready to implement solution
**Next Action:** Run the permission fix script or manual commands above
