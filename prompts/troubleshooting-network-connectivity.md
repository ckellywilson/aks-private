# Troubleshooting Network Connectivity Issues

## Context
Diagnosing and resolving network connectivity issues in a private AKS cluster environment, including problems with storage backend access, cluster connectivity, and application networking.

## Task
Identify, diagnose, and resolve network connectivity issues across the private AKS infrastructure including DNS resolution, routing, firewall rules, and service endpoints.

## Common Connectivity Issues

### 1. Storage Backend Access (403 AuthorizationFailure)
**Symptoms:**
- Terraform init fails with "This request is not authorized to perform this operation"
- GitHub Actions cannot access storage account
- Error codes: AuthorizationFailure, NetworkAclsValidationFailure

**Diagnostic Steps:**
```bash
# Check storage account network rules
az storage account show --name staksdevcus001tfstate --query "networkRuleSet" -o json

# Test connectivity from specific location
az storage blob list --account-name staksdevcus001tfstate --container-name terraform-state --auth-mode login

# Check managed identity permissions
az role assignment list --assignee <managed-identity-principal-id> --scope <storage-account-id>
```

### 2. Private AKS Cluster Access
**Symptoms:**
- kubectl commands fail with connection timeout
- Unable to reach Kubernetes API server
- DNS resolution issues for private endpoint

**Diagnostic Steps:**
```bash
# Check private DNS zone configuration
az network private-dns zone list --resource-group <rg-name>

# Test API server connectivity
nslookup <cluster-fqdn>
kubectl cluster-info

# Verify Bastion connectivity
az network bastion ssh --name <bastion-name> --resource-group <rg-name> --target-resource-id <vm-id> --auth-type password --username <username>
```

### 3. Container Registry Access
**Symptoms:**
- Image pull failures from private ACR
- Authentication errors during image pulls
- Network connectivity timeouts

**Diagnostic Steps:**
```bash
# Check ACR network configuration
az acr show --name <acr-name> --query "networkRuleSet" -o json

# Test ACR connectivity
az acr login --name <acr-name>
docker pull <acr-name>.azurecr.io/<image-name>

# Check AKS to ACR attachment
az aks check-acr --name <cluster-name> --resource-group <rg-name> --acr <acr-name>
```

### 4. Pod-to-Pod Communication
**Symptoms:**
- Services cannot reach other services
- Network policy blocking legitimate traffic
- DNS resolution issues within cluster

**Diagnostic Steps:**
```bash
# Check network policies
kubectl get networkpolicies --all-namespaces

# Test service discovery
kubectl run test-pod --image=busybox -it --rm -- nslookup <service-name>

# Check CNI configuration
kubectl get nodes -o wide
kubectl describe node <node-name>
```

## Diagnostic Tools and Commands

### Network Connectivity Testing
```bash
# Test port connectivity
telnet <hostname> <port>
nc -zv <hostname> <port>

# DNS resolution testing
nslookup <hostname>
dig <hostname>

# Network path testing
traceroute <hostname>
mtr <hostname>
```

### Azure-Specific Diagnostics
```bash
# Network Watcher connectivity check
az network watcher test-connectivity --source-resource <vm-id> --dest-address <target-ip> --dest-port <port>

# VNet peering status
az network vnet peering list --resource-group <rg-name> --vnet-name <vnet-name>

# NSG effective rules
az network nic list-effective-nsg --name <nic-name> --resource-group <rg-name>

# Route table effective routes
az network nic show-effective-route-table --name <nic-name> --resource-group <rg-name>
```

### Kubernetes Diagnostics
```bash
# Pod networking
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous

# Service endpoints
kubectl get endpoints <service-name>
kubectl describe service <service-name>

# Network troubleshooting pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
spec:
  containers:
  - name: debug
    image: nicolaka/netshoot
    command: ["/bin/bash"]
    stdin: true
    tty: true
EOF
```

## Expected Resolutions
- Step-by-step troubleshooting procedures
- Common root causes and their solutions
- Preventive measures and monitoring setup
- Documentation of known issues and workarounds
- Scripts for automated diagnostics and remediation

## Additional Context
- Private networking with service endpoints and private endpoints
- Azure CNI and network policies
- Azure Bastion for secure access
- Managed identities and RBAC configurations
- Multi-environment setup with different network configurations
