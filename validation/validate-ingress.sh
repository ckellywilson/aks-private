#!/bin/bash

# Validate ingress-nginx deployment and configuration
# Usage: ./validate-ingress.sh <environment> [options]

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

# Validation results
VALIDATION_PASSED=true
VALIDATION_RESULTS=()

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

add_result() {
    local status=$1
    local test_name=$2
    local message=$3
    
    VALIDATION_RESULTS+=("$status|$test_name|$message")
    
    if [[ "$status" == "FAIL" ]]; then
        VALIDATION_PASSED=false
        log_error "❌ $test_name: $message"
    elif [[ "$status" == "WARN" ]]; then
        log_warning "⚠️  $test_name: $message"
    else
        log_success "✅ $test_name: $message"
    fi
}

usage() {
    cat <<EOF
Usage: $0 <environment> [options]

Validate ingress-nginx deployment in AKS cluster.

Arguments:
  environment    Target environment (dev, staging, prod)

Options:
  -h, --help     Show this help message
  -v, --verbose  Enable verbose output
  --full         Run full validation including load testing
  --report       Generate detailed validation report

Examples:
  $0 dev                    # Basic validation for dev environment
  $0 staging --full         # Full validation for staging
  $0 prod --report          # Generate detailed report for prod

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are available
    local required_tools=("kubectl" "helm" "curl")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            add_result "FAIL" "Prerequisites" "$tool is required but not installed"
            return 1
        fi
    done
    
    # Check if kubectl is configured
    if ! kubectl config current-context &> /dev/null; then
        add_result "FAIL" "Prerequisites" "kubectl is not configured"
        return 1
    fi
    
    add_result "PASS" "Prerequisites" "All required tools are available"
    return 0
}

validate_namespace() {
    log_info "Validating ingress-nginx namespace..."
    
    if kubectl get namespace ingress-nginx &> /dev/null; then
        add_result "PASS" "Namespace" "ingress-nginx namespace exists"
    else
        add_result "FAIL" "Namespace" "ingress-nginx namespace not found"
        return 1
    fi
    
    # Check namespace labels
    local labels=$(kubectl get namespace ingress-nginx -o jsonpath='{.metadata.labels}')
    if [[ "$labels" == *"environment"* ]]; then
        add_result "PASS" "Namespace Labels" "Environment label is set"
    else
        add_result "WARN" "Namespace Labels" "Environment label is missing"
    fi
    
    return 0
}

validate_helm_release() {
    log_info "Validating Helm release..."
    
    # Check if Helm release exists
    if helm list -n ingress-nginx | grep -q "ingress-nginx"; then
        add_result "PASS" "Helm Release" "ingress-nginx Helm release exists"
        
        # Get release status
        local status=$(helm status ingress-nginx -n ingress-nginx -o json | jq -r '.info.status')
        if [[ "$status" == "deployed" ]]; then
            add_result "PASS" "Helm Status" "Helm release is deployed"
        else
            add_result "FAIL" "Helm Status" "Helm release status is $status"
        fi
    else
        add_result "FAIL" "Helm Release" "ingress-nginx Helm release not found"
        return 1
    fi
    
    return 0
}

validate_pods() {
    log_info "Validating ingress-nginx pods..."
    
    # Check if pods exist
    local pods=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --no-headers 2>/dev/null)
    if [[ -z "$pods" ]]; then
        add_result "FAIL" "Pods Exist" "No ingress-nginx pods found"
        return 1
    fi
    
    # Count running pods
    local running_pods=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    local total_pods=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --no-headers 2>/dev/null | wc -l)
    
    if [[ $running_pods -gt 0 ]]; then
        add_result "PASS" "Pods Running" "$running_pods/$total_pods pods are running"
    else
        add_result "FAIL" "Pods Running" "No pods are running"
        return 1
    fi
    
    # Check pod readiness
    local ready_pods=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -o "true" | wc -l)
    if [[ $ready_pods -gt 0 ]]; then
        add_result "PASS" "Pods Ready" "$ready_pods pods are ready"
    else
        add_result "FAIL" "Pods Ready" "No pods are ready"
        return 1
    fi
    
    return 0
}

validate_service() {
    log_info "Validating ingress-nginx service..."
    
    # Check if service exists
    if kubectl get svc -n ingress-nginx ingress-nginx-controller &> /dev/null; then
        add_result "PASS" "Service Exists" "ingress-nginx-controller service exists"
    else
        add_result "FAIL" "Service Exists" "ingress-nginx-controller service not found"
        return 1
    fi
    
    # Check service type
    local service_type=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.type}')
    if [[ "$service_type" == "LoadBalancer" ]]; then
        add_result "PASS" "Service Type" "Service type is LoadBalancer"
    else
        add_result "WARN" "Service Type" "Service type is $service_type (expected LoadBalancer)"
    fi
    
    # Check external IP
    local external_ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [[ -n "$external_ip" ]]; then
        add_result "PASS" "External IP" "External IP is assigned: $external_ip"
    else
        add_result "WARN" "External IP" "External IP is not yet assigned"
    fi
    
    return 0
}

validate_ingress_class() {
    log_info "Validating ingress class..."
    
    # Check if ingress class exists
    if kubectl get ingressclass nginx &> /dev/null; then
        add_result "PASS" "Ingress Class" "nginx ingress class exists"
        
        # Check if it's the default
        local is_default=$(kubectl get ingressclass nginx -o jsonpath='{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}')
        if [[ "$is_default" == "true" ]]; then
            add_result "PASS" "Default Ingress Class" "nginx is set as default ingress class"
        else
            add_result "WARN" "Default Ingress Class" "nginx is not set as default ingress class"
        fi
    else
        add_result "FAIL" "Ingress Class" "nginx ingress class not found"
        return 1
    fi
    
    return 0
}

validate_configuration() {
    log_info "Validating ingress-nginx configuration..."
    
    # Check replica count based on environment
    local expected_replicas=1
    case "$ENVIRONMENT" in
        prod)
            expected_replicas=3
            ;;
        staging)
            expected_replicas=2
            ;;
        dev)
            expected_replicas=1
            ;;
    esac
    
    local current_replicas=$(kubectl get deployment -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.replicas}')
    if [[ "$current_replicas" -ge "$expected_replicas" ]]; then
        add_result "PASS" "Replica Count" "Replica count is appropriate for $ENVIRONMENT: $current_replicas"
    else
        add_result "WARN" "Replica Count" "Replica count ($current_replicas) is lower than expected for $ENVIRONMENT ($expected_replicas)"
    fi
    
    # Check resource limits
    local cpu_limits=$(kubectl get deployment -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
    local memory_limits=$(kubectl get deployment -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
    
    if [[ -n "$cpu_limits" && -n "$memory_limits" ]]; then
        add_result "PASS" "Resource Limits" "Resource limits are configured: CPU=$cpu_limits, Memory=$memory_limits"
    else
        add_result "WARN" "Resource Limits" "Resource limits are not properly configured"
    fi
    
    return 0
}

validate_connectivity() {
    log_info "Validating ingress-nginx connectivity..."
    
    # Get the external IP or use port-forward
    local external_ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [[ -n "$external_ip" ]]; then
        # Test direct connectivity to ingress controller
        if curl -s -o /dev/null -w "%{http_code}" "http://$external_ip" | grep -q "404"; then
            add_result "PASS" "Connectivity" "Ingress controller is reachable (404 is expected without ingress rules)"
        else
            add_result "WARN" "Connectivity" "Ingress controller connectivity test failed"
        fi
    else
        add_result "WARN" "Connectivity" "Cannot test connectivity - no external IP assigned"
    fi
    
    return 0
}

validate_health_checks() {
    log_info "Validating health checks..."
    
    # Check if health check endpoints are working
    local pod_name=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
    
    if [[ -n "$pod_name" ]]; then
        # Check readiness probe
        if kubectl exec -n ingress-nginx "$pod_name" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:10254/healthz | grep -q "200"; then
            add_result "PASS" "Health Checks" "Health check endpoint is responding"
        else
            add_result "WARN" "Health Checks" "Health check endpoint is not responding properly"
        fi
    else
        add_result "WARN" "Health Checks" "Cannot test health checks - no pods found"
    fi
    
    return 0
}

validate_metrics() {
    log_info "Validating metrics..."
    
    # Check if metrics are enabled
    local pod_name=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}')
    
    if [[ -n "$pod_name" ]]; then
        # Check metrics endpoint
        if kubectl exec -n ingress-nginx "$pod_name" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:10254/metrics | grep -q "200"; then
            add_result "PASS" "Metrics" "Metrics endpoint is available"
        else
            add_result "WARN" "Metrics" "Metrics endpoint is not available"
        fi
    else
        add_result "WARN" "Metrics" "Cannot test metrics - no pods found"
    fi
    
    return 0
}

run_full_validation() {
    log_info "Running full validation (load testing)..."
    
    # Create a test deployment and service
    kubectl create deployment test-app --image=nginx:alpine --replicas=1 -n default --dry-run=client -o yaml | kubectl apply -f -
    kubectl expose deployment test-app --port=80 --target-port=80 -n default --dry-run=client -o yaml | kubectl apply -f -
    
    # Create a test ingress
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-app
            port:
              number: 80
EOF
    
    # Wait for ingress to be ready
    sleep 10
    
    # Test ingress
    local external_ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [[ -n "$external_ip" ]]; then
        if curl -s -H "Host: test.local" "http://$external_ip" | grep -q "nginx"; then
            add_result "PASS" "Full Validation" "Test ingress is working correctly"
        else
            add_result "FAIL" "Full Validation" "Test ingress is not working"
        fi
    else
        add_result "WARN" "Full Validation" "Cannot test ingress - no external IP"
    fi
    
    # Cleanup
    kubectl delete ingress test-ingress -n default --ignore-not-found=true
    kubectl delete service test-app -n default --ignore-not-found=true
    kubectl delete deployment test-app -n default --ignore-not-found=true
    
    return 0
}

generate_report() {
    local report_file="$PROJECT_ROOT/ingress-validation-report-$ENVIRONMENT-$(date +%Y%m%d-%H%M%S).md"
    
    log_info "Generating validation report: $report_file"
    
    cat > "$report_file" <<EOF
# Ingress-nginx Validation Report

**Environment**: $ENVIRONMENT
**Date**: $(date)
**Validation Status**: $(if $VALIDATION_PASSED; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)

## Summary

$(if $VALIDATION_PASSED; then
    echo "All critical validations passed. The ingress-nginx deployment is healthy and ready for use."
else
    echo "Some validations failed. Please review the issues below and take corrective action."
fi)

## Validation Results

| Status | Test | Result |
|--------|------|--------|
EOF
    
    for result in "${VALIDATION_RESULTS[@]}"; do
        IFS='|' read -r status test_name message <<< "$result"
        local emoji
        case "$status" in
            "PASS") emoji="✅" ;;
            "WARN") emoji="⚠️" ;;
            "FAIL") emoji="❌" ;;
        esac
        echo "| $emoji $status | $test_name | $message |" >> "$report_file"
    done
    
    cat >> "$report_file" <<EOF

## Environment Information

### Cluster Information
\`\`\`
$(kubectl cluster-info)
\`\`\`

### Ingress-nginx Pods
\`\`\`
$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o wide)
\`\`\`

### Ingress-nginx Service
\`\`\`
$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o wide)
\`\`\`

### Helm Release
\`\`\`
$(helm list -n ingress-nginx)
\`\`\`

---
Generated by ingress-nginx validation script
EOF
    
    log_success "Validation report generated: $report_file"
}

show_summary() {
    echo
    log_info "Validation Summary for $ENVIRONMENT environment:"
    echo
    
    local passed=0
    local warned=0
    local failed=0
    
    for result in "${VALIDATION_RESULTS[@]}"; do
        IFS='|' read -r status test_name message <<< "$result"
        case "$status" in
            "PASS") ((passed++)) ;;
            "WARN") ((warned++)) ;;
            "FAIL") ((failed++)) ;;
        esac
    done
    
    echo -e "${GREEN}✅ Passed: $passed${NC}"
    echo -e "${YELLOW}⚠️  Warnings: $warned${NC}"
    echo -e "${RED}❌ Failed: $failed${NC}"
    echo
    
    if $VALIDATION_PASSED; then
        log_success "Overall validation: PASSED"
        log_info "The ingress-nginx deployment is healthy and ready for use."
    else
        log_error "Overall validation: FAILED"
        log_error "Please review the failed validations and take corrective action."
    fi
}

main() {
    # Parse arguments
    FULL_VALIDATION=false
    GENERATE_REPORT=false
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --full)
                FULL_VALIDATION=true
                shift
                ;;
            --report)
                GENERATE_REPORT=true
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
    
    log_info "Starting ingress-nginx validation for $ENVIRONMENT environment"
    echo
    
    # Run validation tests
    check_prerequisites
    validate_namespace
    validate_helm_release
    validate_pods
    validate_service
    validate_ingress_class
    validate_configuration
    validate_connectivity
    validate_health_checks
    validate_metrics
    
    # Run full validation if requested
    if [[ "$FULL_VALIDATION" == "true" ]]; then
        run_full_validation
    fi
    
    # Show summary
    show_summary
    
    # Generate report if requested
    if [[ "$GENERATE_REPORT" == "true" ]]; then
        generate_report
    fi
    
    # Exit with appropriate code
    if $VALIDATION_PASSED; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
