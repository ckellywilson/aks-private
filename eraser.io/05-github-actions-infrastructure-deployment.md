# GitHub Actions Infrastructure Deployment Architecture

## Eraser.io Prompt

**Context**: Generate a comprehensive GitHub Actions infrastructure deployment architecture diagram showing the complete workflow for deploying AKS private clusters and Azure infrastructure across multiple environments using Terraform, with security gates, approvals, and automated validation.

## Architecture Overview

Create a detailed diagram showing the end-to-end GitHub Actions infrastructure deployment pipeline that manages the provisioning and configuration of AKS private clusters and supporting Azure services with:

### Infrastructure Deployment Orchestration
- **GitHub Actions workflows** with Terraform-based infrastructure deployment
- **Multi-environment promotion** with progressive infrastructure rollout (dev → staging → production)
- **Infrastructure validation gates** and security checkpoints at each deployment stage
- **Parallel Terraform execution** for independent resource provisioning
- **Infrastructure rollback mechanisms** and disaster recovery procedures

### Infrastructure Security Integration
- **GitHub OIDC** for passwordless authentication to Azure
- **Infrastructure security scanning** (Terraform SAST, infrastructure compliance)
- **Azure Policy compliance** checking and OPA Gatekeeper validation
- **Secret management** through Azure Key Vault integration with GitHub Secrets
- **Least privilege access** with environment-specific service principals for infrastructure deployment

## Detailed Infrastructure Deployment Stages

### Stage 1: Infrastructure Source Code Management
**Trigger Events**:
- **Push to main branch**: Automatic infrastructure deployment to development
- **Pull Request creation**: Terraform plan generation and infrastructure security scan
- **Release tag creation**: Production infrastructure deployment initiation
- **Scheduled runs**: Infrastructure drift detection and compliance checking

**Infrastructure Code Validation**:
- **Terraform code quality**: Linting, formatting, and best practices validation
- **Infrastructure security scanning**: Static analysis with TFSec, Checkov, Terrascan
- **Terraform validation**: Syntax checking, module validation, and dependency analysis
- **Policy compliance**: OPA policy checking for Terraform infrastructure configurations

### Stage 2: Infrastructure Planning (Terraform Plan)
**Development Environment**:
- **Automatic execution** on every push to main branch
- **Terraform plan** generated and stored as artifact
- **Cost estimation** using Infracost integration
- **Security scan** of planned infrastructure changes

**Staging/Production Environments**:
- **Manual trigger** or release-based automatic trigger
- **Terraform plan** with detailed change analysis
- **Security review** and compliance checking
- **Approval requirement** from designated reviewers

**Plan Artifacts**:
```
terraform-plans/
├── dev-plan.json
├── staging-plan.json
├── prod-plan.json
├── cost-estimates/
│   ├── dev-cost.json
│   ├── staging-cost.json
│   └── prod-cost.json
└── security-scans/
    ├── checkov-results.json
    ├── tfsec-results.json
    └── terrascan-results.json
```

### Stage 3: Infrastructure Security and Compliance Gates
**Infrastructure Static Analysis Security Testing**:
- **Terraform security scanning**: Checkov, TFSec, Terrascan for infrastructure vulnerabilities
- **Azure resource security**: Security posture validation for planned Azure resources
- **Network security analysis**: NSG rules, private endpoints, and network isolation validation
- **Compliance framework checking**: CIS Azure benchmarks and industry standards

**Infrastructure Policy Compliance Checking**:
- **Azure Policy simulation**: Test planned infrastructure against Azure policies
- **Terraform compliance policies**: Custom Sentinel or OPA policies for infrastructure standards
- **Cost governance**: Budget impact analysis and cost optimization recommendations
- **Resource governance**: Naming conventions, tagging, and resource organization validation

**Infrastructure Security Gate Results**:
- **Pass**: Proceed to infrastructure deployment automatically
- **Warning**: Require manual review and approval for infrastructure changes
- **Fail**: Block infrastructure deployment and require remediation

### Stage 4: Environment-Specific Infrastructure Deployment

#### Development Infrastructure Deployment
**Execution Model**: Fully automated infrastructure provisioning
- **Terraform apply**: Automatic execution of infrastructure deployment after successful plan
- **AKS cluster provisioning**: Private cluster with system and user node pools
- **Supporting Azure services**: ACR, Key Vault, Storage, Networking, and Monitoring
- **Add-on installation**: Azure Monitor, ingress controllers, and security tools

**Post-Infrastructure Validation**:
- **Infrastructure connectivity tests**: Private endpoint accessibility and network isolation
- **Resource health checks**: AKS cluster health, node status, and service availability
- **Security posture validation**: Network security groups, RBAC, and private cluster access
- **Cost and resource optimization**: Resource utilization and cost baseline establishment

#### Staging Infrastructure Deployment
**Execution Model**: Semi-automated with infrastructure approval gates
- **Manual approval**: Required from infrastructure team lead or designated approver
- **Production-like infrastructure**: Full-scale deployment with private endpoints and security controls
- **Configuration validation**: Environment-specific infrastructure settings verification
- **Infrastructure integration testing**: Cross-service connectivity and dependency validation

**Infrastructure Approval Workflow**:
1. **Infrastructure security review**: Network security and access control validation
2. **Platform team approval**: Resource capacity planning and infrastructure standards compliance
3. **Cost management sign-off**: Budget impact assessment and cost optimization review

#### Production Infrastructure Deployment
**Execution Model**: Fully controlled with multiple infrastructure approval gates
- **Executive approval**: Required for production infrastructure changes
- **Change management**: Integration with ITSM for infrastructure change tracking
- **Maintenance window**: Scheduled infrastructure deployment during approved windows
- **Blue-green infrastructure**: Zero-downtime infrastructure deployment strategy

**Production Infrastructure Gates**:
1. **Infrastructure security review board**: Comprehensive security architecture assessment
2. **Enterprise architecture review**: Infrastructure design and standards validation
3. **Business approval**: Business impact assessment and infrastructure readiness confirmation
4. **Operations team sign-off**: Infrastructure operational readiness and runbook validation

### Stage 5: Post-Infrastructure Deployment Operations

#### Infrastructure Validation and Testing
**Infrastructure Health Testing**:
- **Terraform state validation**: Ensure deployed infrastructure matches desired state
- **Network connectivity tests**: Private endpoint connectivity and network isolation verification
- **Security posture validation**: NSG rules, private cluster access, RBAC, and Key Vault integration
- **Disaster recovery testing**: Infrastructure backup and restore procedures validation

**Infrastructure Performance Testing**:
- **Resource capacity testing**: Node pool scaling and resource allocation validation
- **Network performance tests**: Inter-service communication and bandwidth testing
- **Storage performance validation**: Persistent volume performance and backup/restore testing
- **Security baseline testing**: Infrastructure vulnerability scanning and compliance verification

#### Infrastructure Monitoring and Observability Setup
**Infrastructure Metrics Collection**:
- **Azure Monitor**: Infrastructure insights, resource health, and performance metrics
- **Terraform state monitoring**: Infrastructure drift detection and configuration compliance
- **Cost monitoring**: Resource utilization tracking and cost optimization recommendations
- **Security monitoring**: Infrastructure security events and compliance status

**Infrastructure Alerting Configuration**:
- **Infrastructure health alerts**: Resource availability, capacity, and performance thresholds
- **Security alerts**: Infrastructure security violations and compliance drift
- **Cost alerts**: Budget monitoring and infrastructure cost anomaly detection
- **Configuration drift alerts**: Terraform state drift and configuration changes

### Stage 6: Infrastructure Rollback and Recovery Procedures

#### Automated Infrastructure Rollback Triggers
- **Infrastructure health check failures**: Automatic rollback if post-deployment infrastructure validation fails
- **Security violations**: Immediate infrastructure rollback if security compliance issues are detected
- **Cost threshold breaches**: Rollback if infrastructure costs exceed approved budgets
- **Manual trigger**: Emergency infrastructure rollback capability for operations team

#### Infrastructure Rollback Execution
1. **Terraform state backup validation**: Ensure previous infrastructure state is available and valid
2. **Resource preservation**: Protect critical data and persistent infrastructure resources
3. **Terraform rollback**: Apply previous known-good infrastructure configuration
4. **Infrastructure validation testing**: Confirm infrastructure rollback completed successfully
5. **Incident documentation**: Capture infrastructure rollback reasons and lessons learned

## GitHub Actions Infrastructure Deployment Workflow Architecture

### Infrastructure Workflow Files Structure
```
.github/workflows/
├── terraform-infrastructure-dev.yml       # Development infrastructure deployment
├── terraform-infrastructure-staging.yml   # Staging infrastructure with approvals
├── terraform-infrastructure-production.yml # Production infrastructure with gates
├── infrastructure-security-scan.yml       # Infrastructure security scanning on PR
├── infrastructure-drift-detection.yml     # Scheduled infrastructure drift detection
├── infrastructure-backup-validation.yml   # Infrastructure backup and recovery testing
└── infrastructure-cleanup.yml             # Resource cleanup and cost optimization
```

### Infrastructure Environment-Specific Configuration
**GitHub Environments for Infrastructure**:
- **Development**: No protection rules, automatic infrastructure deployment
- **Staging**: Infrastructure reviewer approval required, environment-specific secrets
- **Production**: Multiple infrastructure reviewers, deployment branches restricted, scheduled deployments

**Infrastructure Secrets Management**:
```
GitHub Infrastructure Secrets (Repository Level):
├── AZURE_CLIENT_ID
├── AZURE_TENANT_ID
├── AZURE_SUBSCRIPTION_ID_DEV
├── AZURE_SUBSCRIPTION_ID_STAGING
├── AZURE_SUBSCRIPTION_ID_PROD
└── TERRAFORM_BACKEND_CONFIG

Infrastructure Environment Secrets:
├── Development/
│   ├── AKS_CLUSTER_NAME
│   ├── ACR_LOGIN_SERVER
│   └── TERRAFORM_STATE_KEY_DEV
├── Staging/
│   ├── AKS_CLUSTER_NAME
│   ├── ACR_LOGIN_SERVER
│   ├── TERRAFORM_STATE_KEY_STAGING
│   └── INFRASTRUCTURE_APPROVAL_WEBHOOK_URL
└── Production/
    ├── AKS_CLUSTER_NAME
    ├── ACR_LOGIN_SERVER
    ├── TERRAFORM_STATE_KEY_PROD
    ├── INFRASTRUCTURE_APPROVAL_WEBHOOK_URL
    └── EMERGENCY_CONTACT_LIST
```

## Visual Guidelines

### Infrastructure Pipeline Flow Visualization
- **Horizontal flow**: Source → Plan → Validate → Deploy → Monitor
- **Parallel stages**: Show concurrent Terraform execution where applicable
- **Decision points**: Diamond shapes for approval gates and infrastructure validation logic
- **Environment progression**: Clear visual indication of dev → staging → prod infrastructure

### Infrastructure Security Gate Indicators
- **Shield icons**: Infrastructure security scanning and validation points
- **Lock icons**: Infrastructure approval gates and access controls
- **Eye icons**: Infrastructure monitoring and observability touchpoints
- **Warning triangles**: Infrastructure risk assessment and manual review points

### Infrastructure Status Indicators
- **Green**: Successful infrastructure deployment and automated progression
- **Yellow**: Manual infrastructure approval required or warning conditions
- **Red**: Failed infrastructure validation or blocked progression
- **Blue**: In-progress or queued infrastructure operations

### Infrastructure Integration Points
- **GitHub icons**: Infrastructure source code management and workflow orchestration
- **Azure icons**: Target cloud infrastructure and services
- **Terraform icons**: Infrastructure as code planning and deployment
- **AKS icons**: Kubernetes cluster infrastructure and networking

## Specific Requirements

1. **Show complete infrastructure deployment flow** from Terraform code commit to production infrastructure
2. **Highlight infrastructure security gates** and compliance checkpoints clearly
3. **Illustrate infrastructure approval processes** and human intervention points
4. **Display parallel Terraform execution** paths and infrastructure dependencies
5. **Include infrastructure rollback mechanisms** and disaster recovery procedures
6. **Show infrastructure monitoring integration** and post-deployment validation

## Expected Output

A comprehensive GitHub Actions infrastructure deployment architecture diagram that clearly demonstrates:
- Complete Terraform workflow orchestration from source to production infrastructure
- Infrastructure security integration and compliance validation at each stage
- Environment-specific infrastructure deployment strategies and approval gates
- Automated infrastructure testing, validation, and monitoring procedures
- Infrastructure rollback mechanisms and disaster recovery procedures
- Integration points with Azure services and infrastructure management tools

This diagram should serve as the definitive reference for infrastructure deployment implementation and be suitable for DevOps infrastructure process reviews and compliance audits.
