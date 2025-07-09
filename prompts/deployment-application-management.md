# Application Deployment and Management on Private AKS

## Context
Deploying, managing, and scaling applications on a private AKS cluster using modern DevOps practices, including containerization, Helm charts, and automated deployment pipelines.

## Task
Design and implement application deployment strategies for private AKS cluster including container builds, Helm chart management, ingress configuration, and operational monitoring.

## Application Architecture
```
Private AKS Cluster
├── Ingress Controller (nginx/AGIC)
│   ├── TLS Termination
│   └── Load Balancing
├── Application Pods
│   ├── Web Frontend
│   ├── API Services
│   └── Background Workers
├── Data Layer
│   ├── Redis Cache
│   ├── PostgreSQL
│   └── Blob Storage
└── Supporting Services
    ├── Monitoring (Prometheus/Grafana)
    ├── Logging (Fluentd/ELK)
    └── Security (Falco/OPA)
```

## Deployment Components

### 1. Container Images
- Base image selection and security scanning
- Multi-stage builds for optimization
- Azure Container Registry integration
- Image versioning and lifecycle management

### 2. Helm Charts
- Chart structure and best practices
- Values files for environment configuration
- Chart testing and validation
- Repository management and versioning

### 3. Ingress and Networking
- Ingress controller configuration (nginx/AGIC)
- SSL/TLS certificate management
- DNS configuration and routing
- Network policies for pod communication

### 4. Configuration Management
- ConfigMaps and Secrets management
- Azure Key Vault integration
- Environment-specific configurations
- Configuration validation and testing

## Deployment Patterns

### GitOps Workflow
```yaml
# Application deployment pipeline
1. Code commit → GitHub
2. Container build → ACR
3. Helm chart update → Artifact repository
4. ArgoCD/Flux → Deployment to AKS
5. Monitoring → Alerts and dashboards
```

### Blue-Green Deployment
```bash
# Deploy new version alongside current
helm upgrade myapp-green ./helm-chart --values values-green.yaml

# Test and validate new version
kubectl run test --image=busybox -- curl http://myapp-green-service

# Switch traffic to new version
kubectl patch service myapp --patch '{"spec":{"selector":{"version":"green"}}}'

# Remove old version
helm uninstall myapp-blue
```

### Canary Deployment
```yaml
# Gradual traffic shifting
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp-rollout
spec:
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 30s}
      - setWeight: 50
      - pause: {duration: 30s}
      - setWeight: 100
```

## Configuration Examples

### Dockerfile Best Practices
```dockerfile
# Multi-stage build example
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS runtime
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .
USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

### Helm Chart Structure
```
myapp/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-prod.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── secret.yaml
└── tests/
    └── test-connection.yaml
```

### Kubernetes Manifests
```yaml
# Deployment with security best practices
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:v1.0.0
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
```

## Operational Considerations

### Monitoring and Alerting
- Application performance monitoring (APM)
- Custom metrics and dashboards
- Log aggregation and analysis
- Error tracking and alerting
- SLO/SLI definition and monitoring

### Scaling and Performance
- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)
- Cluster autoscaling configuration
- Resource quotas and limits
- Performance testing and optimization

### Security and Compliance
- Pod security policies/Pod Security Standards
- Network policies for traffic control
- Image vulnerability scanning
- Runtime security monitoring
- Compliance validation and reporting

## Troubleshooting Common Issues
- Pod startup and readiness failures
- Image pull errors and registry access
- Ingress and service connectivity
- Resource allocation and constraints
- Configuration and secret management
- Performance and scaling issues

## Expected Deliverables
- Container build and deployment pipelines
- Helm chart templates and configurations
- Monitoring and alerting setup
- Documentation and operational runbooks
- Disaster recovery and backup procedures
- Performance optimization recommendations

## Additional Context
- Integration with Azure services (ACR, Key Vault, Monitor)
- CI/CD pipeline integration (GitHub Actions, Azure DevOps)
- Multi-environment deployment strategies
- Cost optimization and resource management
- Security scanning and compliance validation
