#!/bin/bash

# Create sample ingress configurations for testing
# Usage: ./create-sample-ingress.sh <environment> [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENVIRONMENT=${1:-dev}
VALID_ENVIRONMENTS=("dev" "staging" "prod")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat <<EOF
Usage: $0 <environment> [options]

Create sample ingress configurations for testing ingress-nginx.

Arguments:
  environment    Target environment (dev, staging, prod)

Options:
  -h, --help     Show this help message
  -c, --clean    Clean up existing sample resources
  -s, --ssl      Create SSL-enabled ingress (requires cert-manager)
  -v, --verbose  Enable verbose output

Examples:
  $0 dev                    # Create basic sample ingress for dev
  $0 staging --ssl          # Create SSL-enabled sample for staging
  $0 prod --clean           # Clean up sample resources in prod

EOF
}

validate_environment() {
    local env=$1
    for valid_env in "${VALID_ENVIRONMENTS[@]}"; do
        if [[ "$env" == "$valid_env" ]]; then
            return 0
        fi
    done
    return 1
}

create_sample_app() {
    local env=$1
    
    log_info "Creating sample application for $env environment..."
    
    # Create namespace
    kubectl create namespace "sample-app-$env" --dry-run=client -o yaml | kubectl apply -f -
    
    # Create deployment
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: sample-app-$env
  labels:
    app: sample-app
    environment: $env
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
        environment: $env
    spec:
      containers:
      - name: sample-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          value: "$env"
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 32Mi
        volumeMounts:
        - name: config
          mountPath: /usr/share/nginx/html
      volumes:
      - name: config
        configMap:
          name: sample-app-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: sample-app-config
  namespace: sample-app-$env
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Sample App - $env</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                margin: 0;
                padding: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
            }
            .container {
                text-align: center;
                background: rgba(255, 255, 255, 0.1);
                padding: 2rem;
                border-radius: 10px;
                backdrop-filter: blur(10px);
            }
            h1 {
                margin-bottom: 1rem;
                font-size: 2.5rem;
            }
            p {
                font-size: 1.2rem;
                margin: 0.5rem 0;
            }
            .env-badge {
                background: #4CAF50;
                color: white;
                padding: 0.5rem 1rem;
                border-radius: 20px;
                font-weight: bold;
                margin: 1rem 0;
                display: inline-block;
            }
            .info {
                background: rgba(255, 255, 255, 0.2);
                padding: 1rem;
                border-radius: 5px;
                margin-top: 1rem;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Sample Application</h1>
            <div class="env-badge">Environment: $env</div>
            <p>This is a sample application running in the <strong>$env</strong> environment.</p>
            <p>If you can see this page, your ingress-nginx is working correctly!</p>
            <div class="info">
                <p><strong>Hostname:</strong> <span id="hostname"></span></p>
                <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
                <p><strong>User Agent:</strong> <span id="useragent"></span></p>
            </div>
        </div>
        <script>
            document.getElementById('hostname').textContent = window.location.hostname;
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
            document.getElementById('useragent').textContent = navigator.userAgent;
        </script>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: sample-app-$env
  labels:
    app: sample-app
    environment: $env
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
    
    log_success "Sample application created for $env environment"
}

create_basic_ingress() {
    local env=$1
    
    log_info "Creating basic ingress for $env environment..."
    
    # Generate domain based on environment
    local domain
    case "$env" in
        prod)
            domain="app.example.com"
            ;;
        staging)
            domain="staging.app.example.com"
            ;;
        dev)
            domain="dev.app.example.com"
            ;;
    esac
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app-ingress
  namespace: sample-app-$env
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
  labels:
    app: sample-app
    environment: $env
spec:
  ingressClassName: nginx
  rules:
  - host: $domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
EOF
    
    log_success "Basic ingress created for $env environment"
    log_info "Access your application at: http://$domain"
    log_info "Make sure to update your DNS or hosts file to point $domain to the ingress IP"
}

create_ssl_ingress() {
    local env=$1
    
    log_info "Creating SSL-enabled ingress for $env environment..."
    
    # Check if cert-manager is available
    if ! kubectl get crd certificates.cert-manager.io &> /dev/null; then
        log_warning "cert-manager is not installed. Creating ingress without SSL certificate."
        create_basic_ingress "$env"
        return
    fi
    
    # Generate domain based on environment
    local domain
    case "$env" in
        prod)
            domain="app.example.com"
            ;;
        staging)
            domain="staging.app.example.com"
            ;;
        dev)
            domain="dev.app.example.com"
            ;;
    esac
    
    # Create ClusterIssuer for Let's Encrypt (if not exists)
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-$env
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com  # Replace with your email
    privateKeySecretRef:
      name: letsencrypt-$env
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    
    # Create SSL-enabled ingress
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app-ingress
  namespace: sample-app-$env
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-$env"
  labels:
    app: sample-app
    environment: $env
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - $domain
    secretName: sample-app-tls
  rules:
  - host: $domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
EOF
    
    log_success "SSL-enabled ingress created for $env environment"
    log_info "Access your application at: https://$domain"
    log_info "SSL certificate will be automatically provisioned by cert-manager"
}

clean_up_resources() {
    local env=$1
    
    log_info "Cleaning up sample resources for $env environment..."
    
    # Delete ingress
    kubectl delete ingress sample-app-ingress -n "sample-app-$env" --ignore-not-found=true
    
    # Delete service
    kubectl delete service sample-app -n "sample-app-$env" --ignore-not-found=true
    
    # Delete deployment
    kubectl delete deployment sample-app -n "sample-app-$env" --ignore-not-found=true
    
    # Delete configmap
    kubectl delete configmap sample-app-config -n "sample-app-$env" --ignore-not-found=true
    
    # Delete namespace
    kubectl delete namespace "sample-app-$env" --ignore-not-found=true
    
    # Delete ClusterIssuer (only if no other ingresses are using it)
    if [[ "$SSL_ENABLED" == "true" ]]; then
        log_info "Note: ClusterIssuer 'letsencrypt-$env' was not deleted as it might be used by other ingresses"
    fi
    
    log_success "Sample resources cleaned up for $env environment"
}

show_access_info() {
    local env=$1
    
    log_info "Access Information for $env environment:"
    echo
    
    # Get ingress IP
    local ingress_ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    # Get domain
    local domain
    case "$env" in
        prod)
            domain="app.example.com"
            ;;
        staging)
            domain="staging.app.example.com"
            ;;
        dev)
            domain="dev.app.example.com"
            ;;
    esac
    
    if [[ -n "$ingress_ip" ]]; then
        log_info "Ingress IP: $ingress_ip"
        log_info "Domain: $domain"
        echo
        
        if [[ "$SSL_ENABLED" == "true" ]]; then
            log_info "Access URL: https://$domain"
        else
            log_info "Access URL: http://$domain"
        fi
        
        echo
        log_info "To access the application, you need to:"
        echo "1. Update your DNS to point $domain to $ingress_ip"
        echo "2. Or add this to your /etc/hosts file:"
        echo "   $ingress_ip $domain"
        echo
        
        log_info "Test with curl:"
        if [[ "$SSL_ENABLED" == "true" ]]; then
            echo "curl -H 'Host: $domain' https://$ingress_ip"
        else
            echo "curl -H 'Host: $domain' http://$ingress_ip"
        fi
    else
        log_warning "Ingress IP not yet assigned. Please wait a moment and check again."
    fi
}

main() {
    # Parse arguments
    CLEAN_UP=false
    SSL_ENABLED=false
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--clean)
                CLEAN_UP=true
                shift
                ;;
            -s|--ssl)
                SSL_ENABLED=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$ENVIRONMENT" ]]; then
                    ENVIRONMENT=$1
                else
                    log_error "Unexpected argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate environment
    if ! validate_environment "$ENVIRONMENT"; then
        log_error "Invalid environment: $ENVIRONMENT"
        log_error "Valid environments: ${VALID_ENVIRONMENTS[*]}"
        exit 1
    fi
    
    # Enable verbose output if requested
    if [[ "$VERBOSE" == "true" ]]; then
        set -x
    fi
    
    # Check if kubectl is configured
    if ! kubectl config current-context &> /dev/null; then
        log_error "kubectl is not configured. Please configure kubectl to connect to your AKS cluster."
        exit 1
    fi
    
    if [[ "$CLEAN_UP" == "true" ]]; then
        clean_up_resources "$ENVIRONMENT"
    else
        log_info "Creating sample ingress configuration for $ENVIRONMENT environment"
        echo
        
        create_sample_app "$ENVIRONMENT"
        
        if [[ "$SSL_ENABLED" == "true" ]]; then
            create_ssl_ingress "$ENVIRONMENT"
        else
            create_basic_ingress "$ENVIRONMENT"
        fi
        
        # Wait for resources to be ready
        log_info "Waiting for resources to be ready..."
        sleep 5
        
        show_access_info "$ENVIRONMENT"
        
        log_success "Sample ingress configuration created successfully!"
        log_info "You can now test your ingress-nginx setup using the sample application."
    fi
}

# Run main function
main "$@"
