#!/bin/bash

set -e

# GitHub Actions runner entrypoint script
# This script configures and starts the GitHub Actions self-hosted runner
# with enhanced security and monitoring capabilities

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Cleanup function for graceful shutdown
cleanup() {
    log_info "Shutting down runner gracefully..."
    if [ -f "/home/runner/.runner" ]; then
        ./config.sh remove --token "$GITHUB_TOKEN" || true
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Validate required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
    log_error "GITHUB_TOKEN environment variable is required"
    exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
    log_error "GITHUB_REPOSITORY environment variable is required"
    exit 1
fi

if [ -z "$RUNNER_NAME" ]; then
    RUNNER_NAME="terraform-runner-$(hostname)"
    log_warning "RUNNER_NAME not set, using: $RUNNER_NAME"
fi

ENVIRONMENT=${ENVIRONMENT:-dev}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,terraform,$ENVIRONMENT"}

log_info "Starting GitHub Actions runner configuration"
log_info "Environment: $ENVIRONMENT"
log_info "Runner Name: $RUNNER_NAME"
log_info "Labels: $RUNNER_LABELS"

# Pre-flight security checks
log_info "Performing security pre-flight checks..."

# Verify tool versions
terraform_version=$(terraform version -json | jq -r '.terraform_version')
az_version=$(az version --output json | jq -r '.["azure-cli"]')
kubectl_version=$(kubectl version --client=true -o json | jq -r '.clientVersion.gitVersion')
helm_version=$(helm version --template='{{.Version}}')

log_info "Tool versions:"
log_info "  Terraform: $terraform_version"
log_info "  Azure CLI: $az_version"
log_info "  kubectl: $kubectl_version"
log_info "  Helm: $helm_version"

# Verify Azure authentication
if [ "$ENVIRONMENT" != "dev" ]; then
    log_info "Verifying Azure authentication for private environment..."
    if ! az account show &>/dev/null; then
        log_error "Azure authentication failed"
        exit 1
    fi
    log_success "Azure authentication verified"
fi
log_info "Repository: $GITHUB_REPOSITORY"
log_info "Runner Name: $RUNNER_NAME"
log_info "Environment: $ENVIRONMENT"
log_info "Labels: $RUNNER_LABELS"

# Configure the runner
log_info "Configuring GitHub Actions runner..."

# Get registration token
REGISTRATION_TOKEN=$(curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runners/registration-token" \
  | jq -r .token)

if [ "$REGISTRATION_TOKEN" = "null" ] || [ -z "$REGISTRATION_TOKEN" ]; then
    log_error "Failed to get registration token. Check your GitHub token permissions."
    exit 1
fi

# Configure the runner
./config.sh \
    --url "https://github.com/$GITHUB_REPOSITORY" \
    --token "$REGISTRATION_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --work "_work" \
    --unattended \
    --replace \
    --ephemeral

if [ $? -eq 0 ]; then
    log_success "Runner configured successfully"
else
    log_error "Failed to configure runner"
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    log_info "Cleaning up runner registration..."
    
    # Get removal token
    REMOVAL_TOKEN=$(curl -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runners/remove-token" \
      | jq -r .token)
    
    if [ "$REMOVAL_TOKEN" != "null" ] && [ -n "$REMOVAL_TOKEN" ]; then
        ./config.sh remove --token "$REMOVAL_TOKEN"
        log_success "Runner removed from GitHub"
    else
        log_warning "Could not remove runner from GitHub (token issue)"
    fi
}

# Set up signal handlers for graceful shutdown
trap cleanup EXIT
trap cleanup SIGTERM
trap cleanup SIGINT

# Verify Terraform and Azure CLI are available
log_info "Verifying tool installations..."
terraform version
az version --output table
kubectl version --client
helm version

log_success "All tools verified successfully"

# Start the runner
log_info "Starting GitHub Actions runner..."
exec ./run.sh
