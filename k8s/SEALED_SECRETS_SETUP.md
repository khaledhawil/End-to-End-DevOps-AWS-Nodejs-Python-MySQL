# Sealed Secrets Setup Guide

## Overview

This guide explains how to implement Sealed Secrets to encrypt Kubernetes secrets in Git, preventing plaintext secrets from being committed to version control.

## Why Sealed Secrets?

**Current Problem:**
- Secrets are stored as plaintext in `k8s/overlays/*/secrets.yaml`
- Anyone with repository access can read sensitive credentials
- Not compliant with security best practices

**Solution:**
- Sealed Secrets encrypts secrets using asymmetric cryptography
- Only the Sealed Secrets controller in your cluster can decrypt them
- Safe to store encrypted secrets in Git

## Installation

### 1. Install Sealed Secrets Controller

```bash
# Add the Sealed Secrets Helm repository
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

# Install the controller in kube-system namespace
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --set-string fullnameOverride=sealed-secrets-controller

# Verify installation
kubectl get pods -n kube-system | grep sealed-secrets
```

### 2. Install kubeseal CLI

**macOS:**
```bash
brew install kubeseal
```

**Linux:**
```bash
KUBESEAL_VERSION='0.24.0'
wget "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

**Windows:**
```powershell
choco install kubeseal
```

## Usage

### Encrypting Secrets

#### Step 1: Generate Strong Secrets

```bash
# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET: $JWT_SECRET"

# Generate database password
DB_PASSWORD=$(openssl rand -base64 24)
echo "DB_PASSWORD: $DB_PASSWORD"
```

#### Step 2: Create Temporary Secret File

Create a file `temp-secret.yaml` (DO NOT COMMIT THIS):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
  namespace: tms-app
type: Opaque
stringData:
  secret: "YOUR-GENERATED-JWT-SECRET-HERE"
```

#### Step 3: Seal the Secret

```bash
# Encrypt the secret
kubeseal -f temp-secret.yaml -w k8s/overlays/local/sealed-jwt-secret.yaml

# Verify the sealed secret was created
cat k8s/overlays/local/sealed-jwt-secret.yaml
```

#### Step 4: Clean Up

```bash
# IMPORTANT: Delete the temporary plaintext file
rm temp-secret.yaml

# Shred for extra security (Linux/macOS)
shred -u temp-secret.yaml
```

### Example: Complete Secret Migration

```bash
#!/bin/bash
# migrate-to-sealed-secrets.sh

set -e

NAMESPACE="tms-app"
OVERLAY="local"  # Change to staging or production as needed

echo "Generating strong secrets..."
JWT_SECRET=$(openssl rand -base64 32)
DB_PASSWORD=$(openssl rand -base64 24)

echo "Creating sealed secrets..."

# JWT Secret
cat <<EOF | kubeseal -o yaml > k8s/overlays/${OVERLAY}/sealed-jwt-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  secret: "${JWT_SECRET}"
EOF

# Database Password
cat <<EOF | kubeseal -o yaml > k8s/overlays/${OVERLAY}/sealed-db-password.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-password
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  password: "${DB_PASSWORD}"
EOF

# Database Username (less sensitive but for consistency)
cat <<EOF | kubeseal -o yaml > k8s/overlays/${OVERLAY}/sealed-db-username.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-username
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  username: "taskuser"
EOF

# Database Name
cat <<EOF | kubeseal -o yaml > k8s/overlays/${OVERLAY}/sealed-db-name.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-name
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  name: "task_management"
EOF

# SQL Endpoint
cat <<EOF | kubeseal -o yaml > k8s/overlays/${OVERLAY}/sealed-sql-endpoint.yaml
apiVersion: v1
kind: Secret
metadata:
  name: sql-endpoint
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  endpoint: "mysql-service"
EOF

echo "✓ Sealed secrets created successfully!"
echo "⚠️  IMPORTANT: Save these credentials securely:"
echo "JWT_SECRET: ${JWT_SECRET}"
echo "DB_PASSWORD: ${DB_PASSWORD}"
echo ""
echo "Next steps:"
echo "1. Update k8s/overlays/${OVERLAY}/kustomization.yaml"
echo "2. Remove old secrets.yaml"
echo "3. Commit sealed secrets to Git"
```

### Update Kustomization

Edit `k8s/overlays/local/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: tms-app

resources:
  - ../../base
  - ingress.yaml
  - mysql-deployment.yaml
  - mysql-service.yaml
  - mysql-pvc.yaml
  - monitoring-ingress.yaml
  # Add sealed secrets
  - sealed-jwt-secret.yaml
  - sealed-db-password.yaml
  - sealed-db-username.yaml
  - sealed-db-name.yaml
  - sealed-sql-endpoint.yaml

# Remove or comment out:
# - secrets.yaml
```

## Applying Sealed Secrets

```bash
# Apply sealed secrets
kubectl apply -f k8s/overlays/local/

# Verify they were unsealed properly
kubectl get secrets -n tms-app
kubectl get secret jwt-secret -n tms-app -o yaml
```

## Key Management

### Backup Encryption Keys

**CRITICAL:** Back up the Sealed Secrets controller's private key:

```bash
# Export the key
kubectl get secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
  -o yaml > sealed-secrets-master.key

# Store this file in a SECURE location:
# - Password manager
# - Hardware security module
# - Encrypted cloud storage
# DO NOT commit to Git!
```

### Restore Keys (Disaster Recovery)

```bash
# Restore the key in a new cluster
kubectl apply -f sealed-secrets-master.key -n kube-system

# Restart the controller to pick up the key
kubectl rollout restart deployment sealed-secrets-controller -n kube-system
```

### Key Rotation

```bash
# Generate a new key pair (old keys still work for existing sealed secrets)
kubectl delete secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key=active

# Controller will automatically generate a new key
kubectl rollout restart deployment sealed-secrets-controller -n kube-system

# Re-seal all secrets with the new key
# Run the migration script again
```

## Best Practices

### 1. Separate Secrets by Environment

```
k8s/overlays/
├── local/
│   ├── sealed-jwt-secret.yaml
│   └── sealed-db-password.yaml
├── staging/
│   ├── sealed-jwt-secret.yaml
│   └── sealed-db-password.yaml
└── production/
    ├── sealed-jwt-secret.yaml
    └── sealed-db-password.yaml
```

**Different secrets for each environment!**

### 2. Use Strong Scoping

Sealed Secrets support three scopes:
- `strict` (default): namespace + name specific
- `namespace-wide`: any name in the namespace
- `cluster-wide`: any namespace/name

**Recommendation:** Use `strict` for production.

```bash
# Create namespace-scoped sealed secret
kubeseal --scope namespace-wide -f secret.yaml -w sealed-secret.yaml

# Create strictly-scoped (recommended)
kubeseal --scope strict -f secret.yaml -w sealed-secret.yaml
```

### 3. Document Secret Owners

Create `k8s/overlays/production/SECRET_OWNERS.md`:

```markdown
# Secret Ownership

| Secret Name | Owner | Last Rotated | Rotation Policy |
|-------------|-------|--------------|-----------------|
| jwt-secret | DevOps Team | 2026-01-21 | Every 90 days |
| db-password | DBA Team | 2026-01-21 | Every 30 days |
```

### 4. Automate Secret Rotation

Create a GitHub Actions workflow `.github/workflows/rotate-secrets.yml`:

```yaml
name: Rotate Secrets (Manual)

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rotate secrets for'
        required: true
        type: choice
        options:
          - staging
          - production

jobs:
  rotate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate new secrets
        run: |
          JWT_SECRET=$(openssl rand -base64 32)
          echo "::add-mask::$JWT_SECRET"
          echo "JWT_SECRET=$JWT_SECRET" >> $GITHUB_ENV
      
      - name: Seal secrets
        run: |
          # Install kubeseal
          wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
          tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz
          
          # Create sealed secret
          cat <<EOF | ./kubeseal -o yaml > k8s/overlays/${{ inputs.environment }}/sealed-jwt-secret.yaml
          apiVersion: v1
          kind: Secret
          metadata:
            name: jwt-secret
            namespace: tms-app
          type: Opaque
          stringData:
            secret: "${JWT_SECRET}"
          EOF
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore: Rotate secrets for ${{ inputs.environment }}'
          branch: rotate-secrets-${{ inputs.environment }}
          commit-message: 'Rotate secrets for ${{ inputs.environment }}'
```

## Troubleshooting

### Issue: "error: unable to encrypt"

```bash
# Verify controller is running
kubectl get pods -n kube-system | grep sealed-secrets

# Check certificate
kubectl get secret -n kube-system sealed-secrets-key -o yaml

# Re-fetch the certificate
kubeseal --fetch-cert > pub-cert.pem
cat pub-cert.pem
```

### Issue: Sealed secret won't unseal

```bash
# Check controller logs
kubectl logs -n kube-system deployment/sealed-secrets-controller

# Common causes:
# 1. Wrong namespace in sealed secret
# 2. Wrong cluster (sealed secrets are cluster-specific)
# 3. Controller can't decrypt (key mismatch)
```

### Issue: Lost encryption keys

If you didn't back up your keys:
1. Sealed secrets are unrecoverable
2. You must re-generate and re-seal all secrets
3. Update all deployments

**Prevention:** Always backup keys after installation!

## Alternative: External Secrets Operator

For production environments with existing secrets management (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault):

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# Example: AWS Secrets Manager integration
# See: https://external-secrets.io/latest/provider/aws-secrets-manager/
```

## Security Checklist

- [ ] Sealed Secrets controller installed
- [ ] Master key backed up securely
- [ ] All plaintext secrets removed from Git
- [ ] `.gitignore` includes `*secret.yaml` (not `sealed-*.yaml`)
- [ ] Secrets rotated from default values
- [ ] Different secrets per environment
- [ ] Secret rotation policy documented
- [ ] Team trained on sealed secrets workflow
- [ ] Disaster recovery plan tested

## References

- [Sealed Secrets GitHub](https://github.com/bitnami-labs/sealed-secrets)
- [Sealed Secrets Best Practices](https://github.com/bitnami-labs/sealed-secrets#best-practices)
- [External Secrets Operator](https://external-secrets.io/)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
