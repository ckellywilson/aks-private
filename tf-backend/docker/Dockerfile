# Multi-stage build for security and size optimization
FROM ubuntu:22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
ARG TERRAFORM_VERSION=1.7.0
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && chmod +x terraform

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install kubectl and helm
RUN curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl" \
    && chmod +x kubectl
RUN curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar xz \
    && chmod +x linux-amd64/helm

# Production stage
FROM ghcr.io/actions/actions-runner:latest

# Create non-root user for security
USER root
RUN groupadd -r terraform && useradd -r -g terraform -s /bin/bash terraform

# Copy binaries from builder stage
COPY --from=builder /terraform /usr/local/bin/terraform
COPY --from=builder /opt/az /opt/az
COPY --from=builder /kubectl /usr/local/bin/kubectl
COPY --from=builder /linux-amd64/helm /usr/local/bin/helm

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set up symlinks for Azure CLI
RUN ln -s /opt/az/bin/az /usr/local/bin/az

# Security hardening
RUN chmod -R 755 /usr/local/bin \
    && chown -R root:root /usr/local/bin

# Create secure working directory
RUN mkdir -p /home/terraform && chown terraform:terraform /home/terraform

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD terraform version && az version --output none

# Set up runner user with restricted permissions
USER runner
WORKDIR /home/runner

# Labels for metadata
LABEL org.opencontainers.image.title="Terraform GitHub Actions Runner"
LABEL org.opencontainers.image.description="Secure self-hosted runner for Terraform deployments"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="Organization"

# Entry point script
COPY --chown=runner:runner entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
