terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Create namespace for ingress-nginx
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"     = "ingress-nginx"
      "app.kubernetes.io/instance" = "ingress-nginx"
      "environment"                = var.environment
    }
  }
}

# Deploy ingress-nginx using Helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_version
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    templatefile("${path.module}/values-templates/values-${var.environment}.yaml", {
      environment            = var.environment
      enable_internal_lb     = var.enable_internal_load_balancer
      replica_count          = var.ingress_replica_count
      cpu_requests           = var.cpu_requests
      memory_requests        = var.memory_requests
      cpu_limits             = var.cpu_limits
      memory_limits          = var.memory_limits
      enable_metrics         = var.enable_metrics
      enable_prometheus_rule = var.enable_prometheus_rule
      subnet_name            = var.subnet_name
    })
  ]

  depends_on = [kubernetes_namespace.ingress_nginx]

  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Force resource updates if needed
  force_update = false

  # Cleanup on destroy
  cleanup_on_fail = true
}

# Get ingress controller service details
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }
  depends_on = [helm_release.ingress_nginx]
}

# Optional: Create cert-manager for development environment
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = "cert-manager"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [helm_release.ingress_nginx]
}

# Create Let's Encrypt ClusterIssuer for development
resource "kubernetes_manifest" "letsencrypt_issuer" {
  count = var.enable_cert_manager ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# Optional: Deploy Azure Key Vault CSI driver for staging/prod
resource "helm_release" "csi_secrets_store" {
  count = var.enable_azure_key_vault_csi ? 1 : 0

  name       = "csi-secrets-store-provider-azure"
  repository = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart      = "csi-secrets-store-provider-azure"
  version    = var.csi_secrets_store_version
  namespace  = "kube-system"

  depends_on = [helm_release.ingress_nginx]
}
