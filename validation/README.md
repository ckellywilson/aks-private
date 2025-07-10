# Ingress-nginx Validation and Testing

This directory contains validation and testing tools for ingress-nginx in your AKS cluster across multiple environments.

> **Note:** Ingress-nginx deployment is now managed directly through Terraform as part of the main infrastructure deployment. These scripts are for post-deployment validation and testing only.

## Scripts Overview

### 1. `validate-ingress.sh`
Validates the ingress-nginx deployment to ensure it's working correctly.

**Usage:**
```bash
./validate-ingress.sh <environment> [options]
```

**Examples:**
```bash
# Basic validation for dev environment
./validate-ingress.sh dev

# Full validation for staging (includes load testing)
./validate-ingress.sh staging --full

# Generate detailed report for prod
./validate-ingress.sh prod --report
```

**Options:**
- `-h, --help`: Show help message
- `-v, --verbose`: Enable verbose output
- `--full`: Run full validation including load testing
- `--report`: Generate detailed validation report

**Validation Tests:**
- Prerequisites check (kubectl, curl)
- Namespace existence and labels
- Pod status and readiness
- Service configuration and external IP
- Ingress class configuration
- Resource limits and replica counts
- Health check endpoints
- Metrics availability
- Basic connectivity tests

### 2. `create-sample-ingress.sh`
Creates sample ingress configurations for testing your ingress-nginx setup.

**Usage:**
```bash
./create-sample-ingress.sh <environment> [options]
```

**Examples:**
```bash
# Create basic sample ingress for dev
./create-sample-ingress.sh dev

# Create SSL-enabled sample for staging
./create-sample-ingress.sh staging --ssl

# Clean up sample resources in prod
./create-sample-ingress.sh prod --clean
```

**Options:**
- `-h, --help`: Show help message
- `-c, --clean`: Clean up existing sample resources
- `-s, --ssl`: Create SSL-enabled ingress (requires cert-manager)
- `-v, --verbose`: Enable verbose output

**What it creates:**
- Sample nginx application with custom HTML page
- Kubernetes Service for the application
- Ingress resource with environment-specific domain
- Optional SSL certificate (with cert-manager)

## Prerequisites

Before using these scripts, ensure you have:

1. **Required Tools:**
   - `kubectl` - Kubernetes command-line tool
   - `curl` - For connectivity tests
   - `az` - Azure CLI (logged in)

2. **Cluster Access:**
   - kubectl configured to access your AKS cluster
   - Appropriate RBAC permissions for your cluster

3. **Infrastructure Deployed:**
   - AKS cluster and ingress-nginx deployed via Terraform
   - Environment-specific configurations applied

## Quick Start

1. **Deploy infrastructure (including ingress-nginx):**
   ```bash
   cd infra/tf/environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

2. **Validate the ingress-nginx deployment:**
   ```bash
   ./validation/validate-ingress.sh dev
   ```

3. **Create a sample application:**
   ```bash
   ./validation/create-sample-ingress.sh dev
   ```

4. **Test your ingress:**
   ```bash
   # Get the external IP
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   
   # Test with curl (replace IP and domain)
   curl -H 'Host: dev.app.example.com' http://<EXTERNAL_IP>
   ```

## Environment-Specific Configuration

Each environment has different configurations:

### Dev Environment
- **Replicas:** 1
- **Resources:** Minimal (cost-optimized)
- **Domain:** `dev.app.example.com`
- **SSL:** Optional
- **Monitoring:** Basic metrics

### Staging Environment
- **Replicas:** 2
- **Resources:** Moderate
- **Domain:** `staging.app.example.com`
- **SSL:** Recommended
- **Monitoring:** Enhanced metrics

### Production Environment
- **Replicas:** 3+ (high availability)
- **Resources:** Production-grade
- **Domain:** `app.example.com`
- **SSL:** Required
- **Monitoring:** Full observability

## Troubleshooting

### Common Issues

1. **External IP not assigned:**
   ```bash
   # Check service status
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   
   # Check events
   kubectl get events -n ingress-nginx
   ```

2. **Pods not ready:**
   ```bash
   # Check pod status
   kubectl get pods -n ingress-nginx
   
   # Check pod logs
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   ```

3. **Ingress not working:**
   ```bash
   # Check ingress status
   kubectl get ingress -A
   
   # Check ingress controller logs
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   ```

### Validation Failed

If validation fails, check:
1. All prerequisites are met
2. Cluster has sufficient resources
3. Network policies allow traffic
4. DNS/hosts file is configured correctly

### Sample Application Issues

If the sample application is not accessible:
1. Check if the ingress IP is assigned
2. Verify DNS/hosts file configuration
3. Test with direct IP access using Host header
4. Check firewall rules

## Security Considerations

1. **SSL Certificates:**
   - Use cert-manager for automatic SSL certificate management
   - Consider using Azure Key Vault for certificate storage

2. **Network Security:**
   - Configure appropriate network policies
   - Use private load balancers for internal applications
   - Implement WAF rules for production environments

3. **Access Control:**
   - Use RBAC for cluster access
   - Implement proper authentication for applications
   - Consider using Azure AD integration

## Best Practices

1. **Resource Management:**
   - Set appropriate resource limits and requests
   - Use horizontal pod autoscaling for production
   - Monitor resource usage

2. **Monitoring:**
   - Enable metrics collection
   - Set up alerts for critical issues
   - Use Azure Monitor for comprehensive observability

3. **Deployment:**
   - Use Terraform for infrastructure deployment
   - Implement proper CI/CD pipelines
   - Test in staging before production

4. **Backup and Recovery:**
   - Regular backups of ingress configurations
   - Document recovery procedures
   - Test disaster recovery scenarios

## Support

For issues with these scripts:
1. Check the validation report for detailed diagnostics
2. Review the logs from the ingress controller
3. Consult the official ingress-nginx documentation
4. Check Azure AKS documentation for platform-specific issues

## Contributing

When modifying these scripts:
1. Test in dev environment first
2. Update documentation accordingly
3. Follow bash best practices
4. Add appropriate error handling
