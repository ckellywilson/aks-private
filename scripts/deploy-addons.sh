#!/bin/bash

# AKS Add-ons Deployment Script
# This script deploys nginx-ingress and cert-manager to the private AKS cluster
# Must be run from within the VNet (e.g., via Azure Bastion)

set -e

# Configuration
CLUSTER_NAME="aks-cluster-dev-cus-001"
RESOURCE_GROUP="rg-aks-dev-cus-001"
NGINX_VERSION="4.8.3"
CERTMANAGER_VERSION="v1.13.3"
CERT_EMAIL="admin@example.com"  # Change this to your email

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== AKS Add-ons Deployment Script ===${NC}"
echo -e "${YELLOW}This script will deploy nginx-ingress and cert-manager to AKS cluster: ${CLUSTER_NAME}${NC}"
echo

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    echo "Install with: az aks install-cli"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: helm is not installed${NC}"
    echo "Install with: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

echo -e "${GREEN}Prerequisites check passed${NC}"

# Get cluster credentials if not already configured
echo -e "${BLUE}Configuring kubectl access...${NC}"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Verify cluster access
echo -e "${BLUE}Verifying cluster access...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot access the cluster. Make sure you're connected via Azure Bastion${NC}"
    exit 1
fi

echo -e "${GREEN}Cluster access verified${NC}"
kubectl get nodes

echo

# Deploy nginx-ingress
echo -e "${BLUE}=== Deploying nginx-ingress controller ===${NC}"

# Add ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install nginx-ingress
echo -e "${YELLOW}Installing nginx-ingress ${NGINX_VERSION}...${NC}"
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --version $NGINX_VERSION \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true \
  --set controller.replicaCount=2 \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi \
  --set controller.resources.limits.cpu=500m \
  --set controller.resources.limits.memory=512Mi \
  --wait

echo -e "${GREEN}nginx-ingress controller deployed successfully${NC}"

# Wait for load balancer IP
echo -e "${YELLOW}Waiting for LoadBalancer IP assignment...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo -e "${GREEN}nginx-ingress is ready${NC}"
kubectl get svc -n ingress-nginx

echo

# Deploy cert-manager
echo -e "${BLUE}=== Deploying cert-manager ===${NC}"

# Add cert-manager repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
echo -e "${YELLOW}Installing cert-manager ${CERTMANAGER_VERSION}...${NC}"
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version $CERTMANAGER_VERSION \
  --set installCRDs=true \
  --wait

echo -e "${GREEN}cert-manager deployed successfully${NC}"

# Wait for cert-manager to be ready
echo -e "${YELLOW}Waiting for cert-manager to be ready...${NC}"
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=cert-manager \
  --timeout=300s

echo -e "${GREEN}cert-manager is ready${NC}"
kubectl get pods -n cert-manager

echo

# Deploy ClusterIssuer
echo -e "${BLUE}=== Deploying Let's Encrypt ClusterIssuer ===${NC}"

cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $CERT_EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo -e "${GREEN}ClusterIssuer deployed successfully${NC}"

# Verify ClusterIssuer
echo -e "${YELLOW}Verifying ClusterIssuer...${NC}"
sleep 10
kubectl get clusterissuer letsencrypt-prod -o wide

echo

# Deployment summary
echo -e "${GREEN}=== Deployment Summary ===${NC}"
echo -e "${GREEN}✓ nginx-ingress controller deployed in 'ingress-nginx' namespace${NC}"
echo -e "${GREEN}✓ cert-manager deployed in 'cert-manager' namespace${NC}"
echo -e "${GREEN}✓ Let's Encrypt ClusterIssuer 'letsencrypt-prod' created${NC}"

echo
echo -e "${BLUE}=== Next Steps ===${NC}"
echo -e "${YELLOW}1. Get the LoadBalancer IP:${NC}"
echo "   kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller"
echo
echo -e "${YELLOW}2. Configure your DNS to point to the LoadBalancer IP${NC}"
echo
echo -e "${YELLOW}3. Deploy your applications with Ingress resources${NC}"
echo "   See example-app.yaml for reference"
echo
echo -e "${YELLOW}4. Monitor the deployments:${NC}"
echo "   kubectl get pods -n ingress-nginx"
echo "   kubectl get pods -n cert-manager"
echo "   kubectl get clusterissuer"

echo
echo -e "${GREEN}🎉 AKS Add-ons deployment completed successfully!${NC}"
