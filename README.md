# Task Management System - End-to-End DevOps Project

A production-ready task management application demonstrating modern DevOps practices including GitOps, CI/CD automation, container orchestration, and security scanning.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Tools Overview](#tools-overview)
   - [RKE2 Kubernetes](#rke2-kubernetes)
   - [Flux CD](#flux-cd)
   - [Weave GitOps Dashboard](#weave-gitops-dashboard)
   - [GitHub Actions](#github-actions)
   - [Trivy Security Scanner](#trivy-security-scanner)
5. [Prerequisites](#prerequisites)
6. [Deployment Guide](#deployment-guide)
   - [Step 1: Clone the Repository](#step-1-clone-the-repository)
   - [Step 2: Set Up RKE2 Kubernetes Cluster](#step-2-set-up-rke2-kubernetes-cluster)
   - [Step 3: Install Flux CD](#step-3-install-flux-cd)
   - [Step 4: Configure Flux GitRepository](#step-4-configure-flux-gitrepository)
   - [Step 5: Deploy Application with Flux](#step-5-deploy-application-with-flux)
   - [Step 6: Install Weave GitOps Dashboard](#step-6-install-weave-gitops-dashboard)
   - [Step 7: Configure GitHub Actions](#step-7-configure-github-actions)
   - [Step 8: Verify Deployment](#step-8-verify-deployment)
7. [Repository Structure](#repository-structure)
8. [Screenshots](#screenshots)
9. [Troubleshooting](#troubleshooting)

---

## Project Overview

This project implements a complete DevOps pipeline for a cloud-native task management application. The system follows microservices architecture with three core services:

- **Frontend Service**: React-based web application served via Nginx
- **Auth Service**: Node.js/Express API handling user authentication with JWT
- **Task Service**: Python/Flask API managing task CRUD operations

The deployment pipeline uses GitHub Actions for continuous integration, building Docker images on code changes and scanning them for security vulnerabilities. Flux CD monitors the Git repository for manifest changes and automatically synchronizes the desired state to the Kubernetes cluster.

---

## Architecture

```
                                    GitHub Repository
                                           |
                    +----------------------+----------------------+
                    |                                             |
                    v                                             v
             GitHub Actions                                   Flux CD
          (CI/CD Pipeline)                               (GitOps Engine)
                    |                                             |
                    |  Build, Scan, Push                          |  Sync Manifests
                    v                                             v
              Docker Hub                              RKE2 Kubernetes Cluster
          (Container Registry)                                    |
                                                                  |
                                    +-----------------------------+
                                    |
                                    v
                          Nginx Ingress Controller
                                    |
                    +---------------+---------------+
                    |               |               |
                    v               v               v
                Frontend      Auth Service    Task Service
                (React)        (Node.js)       (Python)
                    |               |               |
                    +---------------+---------------+
                                    |
                                    v
                                  MySQL
                              (Database)
```

---

## Technology Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| Container Orchestration | RKE2 Kubernetes | Production-grade Kubernetes distribution |
| GitOps | Flux CD v2 | Continuous delivery and cluster synchronization |
| GitOps Dashboard | Weave GitOps | Visual interface for Flux management |
| CI/CD | GitHub Actions | Automated build, test, and deployment pipelines |
| Security Scanning | Trivy | Container vulnerability scanning |
| Container Registry | Docker Hub | Container image storage |
| Configuration Management | Kustomize | Kubernetes manifest management |
| Ingress | Nginx Ingress Controller | HTTP routing and load balancing |
| Frontend | React 18 + Vite | Single-page application framework |
| Auth Backend | Node.js + Express | Authentication API |
| Task Backend | Python + Flask | Task management API |
| Database | MySQL 8.0 | Persistent data storage |

---

## Tools Overview

### RKE2 Kubernetes

RKE2 is a fully conformant Kubernetes distribution focused on security and compliance. It is designed to meet US Federal Government security requirements while remaining lightweight and easy to operate.

**Key Features:**
- Security-focused with hardened defaults
- Uses containerd as the container runtime
- Automatic certificate rotation
- CIS Kubernetes Benchmark compliant

**Why RKE2 for this project:**
RKE2 provides production-grade Kubernetes with minimal configuration. It includes all necessary components (etcd, containerd, CoreDNS) in a single binary, making cluster setup straightforward while maintaining enterprise security standards.

**Cluster Architecture:**
```
+------------------+     +------------------+     +------------------+
|   Control Plane  |     |   Worker Node    |     |   Worker Node    |
|   (Master)       |     |                  |     |                  |
|                  |     |                  |     |                  |
|  - API Server    |     |  - kubelet       |     |  - kubelet       |
|  - etcd          |     |  - containerd    |     |  - containerd    |
|  - Controller    |     |  - kube-proxy    |     |  - kube-proxy    |
|  - Scheduler     |     |                  |     |                  |
+------------------+     +------------------+     +------------------+
```

---

### Flux CD

Flux CD is a GitOps operator for Kubernetes. It continuously monitors Git repositories and automatically applies changes to the cluster, ensuring the cluster state always matches what is defined in Git.

**Key Components:**
- **Source Controller**: Monitors Git repositories for changes
- **Kustomize Controller**: Builds and applies Kustomize configurations
- **Helm Controller**: Manages Helm chart releases
- **Notification Controller**: Sends alerts on reconciliation events

**How Flux Works:**
```
1. Developer pushes code to Git
           |
           v
2. Source Controller detects changes
           |
           v
3. Kustomize Controller builds manifests
           |
           v
4. Controller applies to Kubernetes cluster
           |
           v
5. Cluster state matches Git (reconciled)
```

**GitOps Benefits:**
- Complete audit trail of all changes
- Easy rollback to any previous state
- Drift detection and automatic correction
- Declarative configuration management

---

### Weave GitOps Dashboard

Weave GitOps provides a graphical user interface for managing Flux CD resources. It allows operators to visualize GitOps pipelines, monitor synchronization status, and troubleshoot deployment issues.

**Dashboard Features:**
- Visual overview of all Flux resources
- Real-time synchronization status
- Application health monitoring
- Easy navigation between sources, kustomizations, and helm releases

**Accessing the Dashboard:**
The dashboard is deployed as a Kubernetes service and can be accessed via port-forwarding or ingress.

---

### GitHub Actions

GitHub Actions provides CI/CD automation directly integrated with the source repository. The pipeline in this project implements intelligent change detection, building only services that have been modified.

**Pipeline Stages:**
1. **Change Detection**: Identifies which services have changed
2. **Build**: Creates Docker images for modified services
3. **Security Scan**: Runs Trivy vulnerability scanning
4. **Push**: Uploads images to Docker Hub
5. **Update Manifests**: Updates Kubernetes manifests with new image tags
6. **Notify**: Sends Slack/email notifications for vulnerabilities

**Pipeline Flow:**
```
Code Push --> Change Detection --> Build Images --> Trivy Scan
                                                        |
                                        +---------------+---------------+
                                        |                               |
                                  Vulnerabilities                  No Issues
                                   Detected                          Found
                                        |                               |
                                        v                               v
                                 Send Alerts                    Push to Registry
                                        |                               |
                                        +---------------+---------------+
                                                        |
                                                        v
                                              Update K8s Manifests
                                                        |
                                                        v
                                               Commit to Git
                                                        |
                                                        v
                                              Flux Detects Changes
                                                        |
                                                        v
                                              Deploy to Cluster
```

---

### Trivy Security Scanner

Trivy is a comprehensive security scanner that detects vulnerabilities in container images, file systems, and Git repositories. The CI pipeline integrates Trivy to scan every built image before deployment.

**Scan Capabilities:**
- OS package vulnerabilities (Alpine, Debian, Ubuntu, etc.)
- Application dependencies (npm, pip, go modules, etc.)
- Infrastructure as Code misconfigurations
- Secret detection

**Severity Levels:**
- CRITICAL: Immediate action required
- HIGH: Should be addressed promptly
- MEDIUM: Plan for remediation
- LOW: Address when convenient

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| kubectl | 1.28+ | Kubernetes CLI |
| Flux CLI | 2.0+ | Flux command-line tool |
| Git | 2.30+ | Version control |
| Docker | 20.10+ | Container runtime (for local testing) |

### Required Accounts

- GitHub account with repository access
- Docker Hub account for container images

### System Requirements

- CPU: Minimum 4 cores
- Memory: Minimum 8GB RAM (16GB recommended)
- Storage: Minimum 50GB available disk space
- Network: Internet connectivity

---

## Deployment Guide

### Step 1: Clone the Repository

Clone the project repository to your local machine.

**Purpose:** Download all source code, Kubernetes manifests, and CI/CD configurations.

```bash
git clone https://github.com/khaledhawil/End-to-End-DevOps-AWS-Nodejs-Python-MySQL.git
cd End-to-End-DevOps-AWS-Nodejs-Python-MySQL
```

**Expected Result:** A directory containing the complete project structure.

---

### Step 2: Set Up RKE2 Kubernetes Cluster

Install and configure RKE2 on your server nodes.

**Purpose:** Create the Kubernetes cluster where applications will be deployed.

**On the Control Plane Node:**

```bash
# Download and install RKE2
curl -sfL https://get.rke2.io | sh -

# Enable and start RKE2 server
systemctl enable rke2-server.service
systemctl start rke2-server.service

# Wait for the cluster to be ready
/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes
```

**On Worker Nodes:**

```bash
# Download RKE2
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

# Configure the agent to connect to the server
mkdir -p /etc/rancher/rke2/
cat <<EOF > /etc/rancher/rke2/config.yaml
server: https://<CONTROL_PLANE_IP>:9345
token: <NODE_TOKEN>
EOF

# Start the agent
systemctl enable rke2-agent.service
systemctl start rke2-agent.service
```

**Configure kubectl:**

```bash
# Copy kubeconfig to your local machine
mkdir -p ~/.kube
cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
chmod 600 ~/.kube/config

# Update the server address if accessing remotely
sed -i 's/127.0.0.1/<CONTROL_PLANE_IP>/g' ~/.kube/config

# Verify cluster access
kubectl get nodes
```

**Expected Result:**
```
NAME          STATUS   ROLES                       AGE   VERSION
master-node   Ready    control-plane,etcd,master   5m    v1.28.x+rke2r1
worker-1      Ready    <none>                      3m    v1.28.x+rke2r1
worker-2      Ready    <none>                      3m    v1.28.x+rke2r1
```

---

### Step 3: Install Flux CD

Install Flux CD components in the Kubernetes cluster.

**Purpose:** Enable GitOps-based continuous delivery for automatic synchronization between Git and the cluster.

```bash
# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Verify Flux CLI installation
flux --version

# Install Flux components in the cluster
flux install

# Verify Flux pods are running
kubectl get pods -n flux-system
```

**Expected Result:**
```
NAME                                       READY   STATUS    RESTARTS   AGE
helm-controller-xxxxxxxxxx-xxxxx           1/1     Running   0          60s
kustomize-controller-xxxxxxxxxx-xxxxx      1/1     Running   0          60s
notification-controller-xxxxxxxxxx-xxxxx   1/1     Running   0          60s
source-controller-xxxxxxxxxx-xxxxx         1/1     Running   0          60s
```

**Understanding Flux Controllers:**
- **source-controller**: Fetches manifests from Git repositories
- **kustomize-controller**: Builds and applies Kustomize configurations
- **helm-controller**: Manages Helm chart releases
- **notification-controller**: Handles alerts and notifications

---

### Step 4: Configure Flux GitRepository

Create a GitRepository resource that tells Flux where to find the Kubernetes manifests.

**Purpose:** Connect Flux to the Git repository containing the application manifests.

```bash
# Apply the GitRepository configuration
kubectl apply -f flux/clusters/local/git-repository.yaml

# Verify the repository is syncing
flux get sources git
```

**GitRepository Configuration (flux/clusters/local/git-repository.yaml):**
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: task-management-system
  namespace: flux-system
spec:
  interval: 30s
  ref:
    branch: master
  url: https://github.com/khaledhawil/End-to-End-DevOps-AWS-Nodejs-Python-MySQL.git
```

**Expected Result:**
```
NAME                     REVISION              SUSPENDED   READY   MESSAGE
task-management-system   master@sha1:xxxxxxx   False       True    stored artifact for revision
```

---

### Step 5: Deploy Application with Flux

Create a Kustomization resource that tells Flux which manifests to apply.

**Purpose:** Instruct Flux to deploy the application using the Kustomize overlays.

```bash
# Apply the Kustomization configuration
kubectl apply -f flux/clusters/local/kustomization-app.yaml

# Monitor the deployment
flux get kustomizations

# Watch Flux reconciliation
flux logs --follow
```

**Kustomization Configuration (flux/clusters/local/kustomization-app.yaml):**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: task-management-system-local
  namespace: flux-system
spec:
  interval: 1m0s
  path: ./k8s/overlays/local
  prune: true
  sourceRef:
    kind: GitRepository
    name: task-management-system
  timeout: 3m0s
  wait: true
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: frontend
      namespace: tms-app
    - apiVersion: apps/v1
      kind: Deployment
      name: auth-service
      namespace: tms-app
    - apiVersion: apps/v1
      kind: Deployment
      name: task-service
      namespace: tms-app
    - apiVersion: apps/v1
      kind: Deployment
      name: mysql
      namespace: tms-app
```

**Verify Application Deployment:**
```bash
# Check all resources in the application namespace
kubectl get all -n tms-app

# Verify pods are running
kubectl get pods -n tms-app

# Check services
kubectl get svc -n tms-app
```

**Expected Result:**
```
NAME                               READY   STATUS    RESTARTS   AGE
pod/auth-service-xxxxxxxxxx-xxxxx  1/1     Running   0          2m
pod/frontend-xxxxxxxxxx-xxxxx      1/1     Running   0          2m
pod/mysql-xxxxxxxxxx-xxxxx         1/1     Running   0          2m
pod/task-service-xxxxxxxxxx-xxxxx  1/1     Running   0          2m

NAME                       TYPE        CLUSTER-IP      PORT(S)
service/auth-service       ClusterIP   10.43.x.x       80/TCP
service/frontend-service   ClusterIP   10.43.x.x       80/TCP
service/mysql-service      ClusterIP   10.43.x.x       3306/TCP
service/task-service       ClusterIP   10.43.x.x       80/TCP
```

---

### Step 6: Install Weave GitOps Dashboard

Deploy the Weave GitOps dashboard for visual Flux management.

**Purpose:** Provide a graphical interface to monitor and manage GitOps deployments.

**Create Admin Credentials:**
```bash
# Generate bcrypt hashed password
PASSWORD="admin123"
HASHED_PASSWORD=$(htpasswd -nbB admin "$PASSWORD" | cut -d: -f2)

# Create the admin secret
kubectl create secret generic cluster-user-auth \
  --namespace flux-system \
  --from-literal=username=admin \
  --from-literal=password="$HASHED_PASSWORD"
```

**Install Weave GitOps via HelmRelease:**
```bash
# Create HelmRepository for Weave GitOps
cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: ww-gitops
  namespace: flux-system
spec:
  interval: 1h0m0s
  url: https://helm.gitops.weave.works
EOF

# Create HelmRelease for Weave GitOps
cat <<EOF | kubectl apply -f -
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: ww-gitops
  namespace: flux-system
spec:
  interval: 1h0m0s
  chart:
    spec:
      chart: weave-gitops
      sourceRef:
        kind: HelmRepository
        name: ww-gitops
  values:
    adminUser:
      create: true
      createClusterRole: true
      createSecret: false
      username: admin
EOF
```

**Access the Dashboard:**
```bash
# Port-forward the Weave GitOps service
kubectl port-forward svc/ww-gitops-weave-gitops -n flux-system 9001:9001

# Open in browser: http://localhost:9001
# Login with: admin / admin123
```

---

### Step 7: Configure GitHub Actions

Set up the CI/CD pipeline for automated builds and deployments.

**Purpose:** Automate container image building, security scanning, and Kubernetes manifest updates.

**Required GitHub Secrets:**

Navigate to your GitHub repository Settings > Secrets and variables > Actions, then add:

| Secret Name | Description |
|-------------|-------------|
| DOCKER_USERNAME | Docker Hub username |
| DOCKER_PASSWORD | Docker Hub password or access token |
| SLACK_WEBHOOK_URL | (Optional) Slack webhook for notifications |
| MAIL_SERVER | (Optional) SMTP server for email alerts |
| MAIL_PORT | (Optional) SMTP port (usually 587) |
| MAIL_USERNAME | (Optional) SMTP username |
| MAIL_PASSWORD | (Optional) SMTP password |
| MAIL_TO | (Optional) Recipient email addresses |

**Pipeline Trigger:**

The pipeline automatically runs when changes are pushed to the following directories:
- services/auth-service/
- services/task-service/
- services/frontend/

**Manual Trigger:**

You can also trigger the pipeline manually from the GitHub Actions tab.

---

### Step 8: Verify Deployment

Confirm that all components are working correctly.

**Check Flux Status:**
```bash
# Verify all Flux resources
flux get all

# Check GitRepository sync status
flux get sources git

# Check Kustomization status
flux get kustomizations
```

**Check Application Status:**
```bash
# Verify all pods are running
kubectl get pods -n tms-app

# Check ingress configuration
kubectl get ingress -n tms-app

# Get the application URL
kubectl get ingress -n tms-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}'
```

**Test the Application:**
```bash
# Get ingress IP
INGRESS_IP=$(kubectl get ingress -n tms-app tms-frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test frontend
curl -I http://$INGRESS_IP/

# Test auth service health
curl http://$INGRESS_IP/api/auth/health

# Test task service health
curl http://$INGRESS_IP/api/tasks/health
```

**Expected Results:**
- Frontend returns HTTP 200 with HTML content
- Auth service returns: {"status": "healthy", "service": "auth-service"}
- Task service returns: {"status": "healthy", "service": "task-service"}

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── ci-cd-pipeline.yml       # GitHub Actions CI/CD pipeline
│
├── flux/
│   └── clusters/
│       ├── local/                   # Local environment Flux config
│       │   ├── git-repository.yaml  # Git source definition
│       │   └── kustomization-app.yaml
│       ├── staging/                 # Staging environment config
│       └── production/              # Production environment config
│
├── k8s/
│   ├── base/                        # Base Kubernetes manifests
│   │   ├── namespace.yaml
│   │   ├── auth-service-deployment.yaml
│   │   ├── auth-service.yaml
│   │   ├── task-service-deployment.yaml
│   │   ├── task-service.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── frontend-service.yaml
│   │   ├── mysql-configmap.yaml
│   │   ├── network-policy.yaml
│   │   ├── pdb.yaml
│   │   ├── rbac.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── local/                   # Local environment overlay
│       │   ├── kustomization.yaml
│       │   ├── ingress.yaml
│       │   ├── mysql-deployment.yaml
│       │   ├── mysql-pvc.yaml
│       │   ├── mysql-service.yaml
│       │   └── secrets.yaml
│       ├── staging/                 # Staging overlay
│       └── production/              # Production overlay
│
├── services/
│   ├── auth-service/                # Node.js authentication service
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── server.js
│   ├── task-service/                # Python task management service
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app.py
│   └── frontend/                    # React frontend application
│       ├── Dockerfile
│       ├── package.json
│       ├── vite.config.js
│       └── src/
│
├── scripts/
│   └── verify-security.sh           # Security verification script
│
└── README.md                        # This file
```

---

## Screenshots

### Task Management Application
The main dashboard showing task management interface.

![Task Application](Screenshots/task-app.png)

### CI/CD Pipeline
GitHub Actions workflow showing build and deployment stages.

![CI/CD Pipeline](Screenshots/cd-pipline.png)

### Pipeline Summary
Overview of pipeline execution with all jobs.

![Pipeline Summary](Screenshots/pipline-summary.png)

### Kubernetes Cluster
RKE2 cluster nodes and workloads.

![Kubernetes Cluster](Screenshots/k8s-cluster.png)

### Weave GitOps Dashboard
Flux resources visualized in Weave GitOps.

![Weave GitOps GUI](Screenshots/weavy-gui.png)

### Application in Weave GitOps
Application status in the GitOps dashboard.

![App in Weave](Screenshots/app-on-weavy.png)

### Slack Notifications
Vulnerability alerts sent to Slack.

![Slack Notifications](Screenshots/slack-.png)

---

## Troubleshooting

### Flux Not Syncing

**Symptom:** Kustomization shows "False" in READY column.

**Solution:**
```bash
# Check Flux logs
flux logs

# Force reconciliation
flux reconcile source git task-management-system
flux reconcile kustomization task-management-system-local

# Check for errors
kubectl describe kustomization task-management-system-local -n flux-system
```

### Pods Not Starting

**Symptom:** Pods stuck in Pending or CrashLoopBackOff.

**Solution:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n tms-app

# Check container logs
kubectl logs <pod-name> -n tms-app

# Check resource availability
kubectl top nodes
kubectl describe node <node-name>
```

### Database Connection Issues

**Symptom:** Services cannot connect to MySQL.

**Solution:**
```bash
# Verify MySQL is running
kubectl get pods -n tms-app -l app=mysql

# Check MySQL logs
kubectl logs -n tms-app -l app=mysql

# Test database connectivity
kubectl exec -it deployment/mysql -n tms-app -- mysql -u taskuser -p -e "SELECT 1;"

# Verify secrets
kubectl get secrets -n tms-app
```

### Weave GitOps Empty Dashboard

**Symptom:** Dashboard shows no resources after login.

**Solution:**
```bash
# Verify RBAC is configured
kubectl get clusterrolebinding | grep wego

# Recreate admin credentials
kubectl delete secret cluster-user-auth -n flux-system
HASHED=$(htpasswd -nbB admin admin123 | cut -d: -f2)
kubectl create secret generic cluster-user-auth \
  --namespace flux-system \
  --from-literal=username=admin \
  --from-literal=password="$HASHED"

# Restart Weave GitOps
kubectl rollout restart deployment ww-gitops-weave-gitops -n flux-system
```

---

## License

This project is provided for educational and demonstration purposes.

---

## Contributing

Contributions are welcome. Please submit pull requests with clear descriptions of changes.
