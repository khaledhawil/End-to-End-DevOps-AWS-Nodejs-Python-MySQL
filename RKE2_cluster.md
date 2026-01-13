# RKE2 Cluster Setup Guide

Complete guide to setting up a production-ready RKE2 (Rancher Kubernetes Engine 2) cluster on 3 Ubuntu VMs.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [VM Preparation](#vm-preparation)
4. [RKE2 Server Installation (Master Node)](#rke2-server-installation-master-node)
5. [RKE2 Agent Installation (Worker Nodes)](#rke2-agent-installation-worker-nodes)
6. [Cluster Verification](#cluster-verification)
7. [Installing kubectl](#installing-kubectl)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware Requirements

- **Master Node (Server)**: Minimum 2 CPU cores, 4GB RAM, 50GB storage
- **Worker Nodes (Agents)**: Minimum 2 CPU cores, 4GB RAM, 50GB storage each
- All VMs should have network connectivity to each other

### Software Requirements

- Ubuntu 20.04 LTS or Ubuntu 22.04 LTS on all 3 VMs
- Root or sudo access on all VMs
- Static IP addresses configured on all VMs
- Hostnames properly configured on all VMs

### Network Requirements

- Port 9345 (RKE2 supervisor API) open between server and agents
- Port 6443 (Kubernetes API) open for external access to master
- Port 10250 (kubelet) open on all nodes
- Port 2379-2380 (etcd) open on server node

## Architecture Overview

In this setup, you will have:

- **1 Server Node (Master)**: Runs the Kubernetes control plane components (API server, scheduler, controller manager, etcd)
- **2 Agent Nodes (Workers)**: Run your application workloads

```
┌─────────────────────────┐
│   Master Node (Server)  │
│   - Control Plane       │
│   - etcd                │
│   - API Server          │
└───────────┬─────────────┘
            │
    ┌───────┴────────┐
    │                │
┌───▼────────┐  ┌───▼────────┐
│ Worker 1   │  │ Worker 2   │
│ (Agent)    │  │ (Agent)    │
└────────────┘  └────────────┘
```

## VM Preparation

Perform these steps on all 3 VMs (master and both workers).

### Step 1: Update System Packages

Update the package list and upgrade installed packages to ensure you have the latest security patches.

```bash
sudo apt update && sudo apt upgrade -y
```

**What this does**: Downloads the latest package information and upgrades all installed packages to their newest versions.

### Step 2: Set Hostnames

Set unique hostnames for each VM to easily identify them in the cluster.

On Master Node:
```bash
sudo hostnamectl set-hostname rke2-master
```

On Worker Node 1:
```bash
sudo hostnamectl set-hostname rke2-worker1
```

On Worker Node 2:
```bash
sudo hostnamectl set-hostname rke2-worker2
```

**What this does**: Assigns a permanent hostname to each server that persists across reboots.

### Step 3: Configure /etc/hosts File

Add entries to the hosts file on all nodes so they can resolve each other by hostname.

Edit the file on all 3 VMs:
```bash
sudo nano /etc/hosts
```

Add these lines (replace with your actual IP addresses):
```
192.168.1.10  rke2-master
192.168.1.11  rke2-worker1
192.168.1.12  rke2-worker2
```

**What this does**: Creates a local DNS mapping so nodes can communicate using hostnames instead of IP addresses.

### Step 4: Disable Swap

Kubernetes requires swap to be disabled for optimal performance.

```bash
sudo swapoff -a
```

Make it permanent by commenting out swap entries:
```bash
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

**What this does**: Disables virtual memory swap space which can interfere with Kubernetes memory management.

### Step 5: Configure Firewall (UFW)

If UFW firewall is enabled, configure the necessary ports.

On Master Node:
```bash
sudo ufw allow 9345/tcp  # RKE2 supervisor API
sudo ufw allow 6443/tcp  # Kubernetes API
sudo ufw allow 10250/tcp # Kubelet
sudo ufw allow 2379:2380/tcp # etcd
```

On Worker Nodes:
```bash
sudo ufw allow 9345/tcp  # RKE2 supervisor API
sudo ufw allow 10250/tcp # Kubelet
```

**What this does**: Opens the required network ports for cluster communication while maintaining security.

### Step 6: Load Kernel Modules

Enable required kernel modules for networking.

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

**What this does**: Loads kernel modules needed for container networking and overlay filesystem support.

### Step 7: Configure Sysctl Parameters

Set kernel parameters for Kubernetes networking.

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

**What this does**: Enables IP forwarding and allows bridge network traffic to be processed by iptables for proper routing.

## RKE2 Server Installation (Master Node)

Perform these steps only on the master node.

### Step 1: Download and Install RKE2 Server

Download the RKE2 installation script and run it with server configuration.

```bash
curl -sfL https://get.rke2.io | sudo sh -
```

**What this does**: Downloads and executes the official RKE2 installation script which installs all necessary binaries and systemd services.

### Step 2: Enable and Start RKE2 Server Service

Enable the service to start automatically on boot and start it now.

```bash
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
```

**What this does**: Configures the RKE2 server service to start automatically when the system boots and starts the service immediately.

### Step 3: Wait for Installation to Complete

The RKE2 server takes a few minutes to initialize. Monitor the logs to ensure it starts successfully.

```bash
sudo journalctl -u rke2-server -f
```

Press `Ctrl+C` to exit when you see messages indicating the server is ready (look for "Node controller sync successful").

**What this does**: Shows real-time logs from the RKE2 server service to verify it's starting correctly.

### Step 4: Configure kubectl Access

Set up environment variables and symlink to use kubectl.

```bash
# Add to your shell profile for permanent access
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
source ~/.bashrc

# Create symlink for kubectl
sudo ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
```

**What this does**: Configures your shell to find the kubectl command and know where the cluster configuration file is located.

### Step 5: Verify Server is Running

Check that the master node is ready.

```bash
sudo kubectl get nodes
```

You should see output showing the master node in "Ready" status.

**What this does**: Queries the Kubernetes API to display all nodes currently registered in the cluster.

### Step 6: Retrieve the Node Token

Get the token that worker nodes will use to join the cluster.

```bash
sudo cat /var/lib/rancher/rke2/server/node-token
```

**Important**: Copy this token value. You will need it for the worker nodes. The token looks like: `K10abc123def456...::server:xyz789...`

**What this does**: Displays the secret authentication token that validates worker nodes when they attempt to join the cluster.

## RKE2 Agent Installation (Worker Nodes)

Perform these steps on both worker nodes.

### Step 1: Create RKE2 Configuration Directory

Create the directory where RKE2 stores its configuration.

```bash
sudo mkdir -p /etc/rancher/rke2/
```

**What this does**: Creates the configuration directory with proper permissions for RKE2.

### Step 2: Create Configuration File

Create a configuration file that tells the agent how to connect to the server.

```bash
sudo nano /etc/rancher/rke2/config.yaml
```

Add the following content (replace `<MASTER_IP>` with your master node IP and `<TOKEN>` with the token from Step 6 above):

```yaml
server: https://<MASTER_IP>:9345
token: <TOKEN>
```

Example:
```yaml
server: https://192.168.1.10:9345
token: K10abc123def456...::server:xyz789...
```

Save the file (Ctrl+O, Enter, then Ctrl+X in nano).

**What this does**: Configures the worker node with the master node's address and the authentication token needed to join the cluster.

### Step 3: Download and Install RKE2 Agent

Download the RKE2 installation script and run it with agent configuration.

```bash
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sudo sh -
```

**What this does**: Downloads and installs RKE2 in agent mode, which is designed for worker nodes.

### Step 4: Enable and Start RKE2 Agent Service

Enable the service to start automatically on boot and start it now.

```bash
sudo systemctl enable rke2-agent.service
sudo systemctl start rke2-agent.service
```

**What this does**: Configures the RKE2 agent service to start automatically when the system boots and starts the service immediately.

### Step 5: Monitor Agent Logs

Watch the logs to ensure the agent connects successfully to the server.

```bash
sudo journalctl -u rke2-agent -f
```

Press `Ctrl+C` to exit when you see messages indicating successful connection (look for "Successfully registered node").

**What this does**: Shows real-time logs from the RKE2 agent service to verify it's connecting to the master node successfully.

## Cluster Verification

Perform these steps on the master node to verify your cluster is fully operational.

### Step 1: Check All Nodes

Verify all three nodes appear in the cluster.

```bash
kubectl get nodes
```

Expected output:
```
NAME            STATUS   ROLES                       AGE   VERSION
rke2-master     Ready    control-plane,etcd,master   10m   v1.28.x+rke2rx
rke2-worker1    Ready    <none>                      5m    v1.28.x+rke2rx
rke2-worker2    Ready    <none>                      5m    v1.28.x+rke2rx
```

All nodes should show "Ready" status.

**What this does**: Lists all nodes registered in the cluster along with their status, roles, and Kubernetes version.

### Step 2: Check Node Details

Get detailed information about a specific node.

```bash
kubectl describe node rke2-master
```

**What this does**: Shows comprehensive information about the node including capacity, conditions, and system info.

### Step 3: Check System Pods

Verify that all system components are running correctly.

```bash
kubectl get pods --all-namespaces
```

All pods should be in "Running" or "Completed" status.

**What this does**: Lists all pods across all namespaces, showing the status of core Kubernetes components.

### Step 4: Check Cluster Info

Get general information about the cluster.

```bash
kubectl cluster-info
```

**What this does**: Displays URLs for the Kubernetes control plane services and DNS.

## Installing kubectl

If you want to manage the cluster from your local machine instead of SSH-ing into the master node:

### Step 1: Install kubectl on Local Machine

On Ubuntu/Debian:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**What this does**: Downloads the latest stable kubectl binary and installs it in your system path.

### Step 2: Copy Kubeconfig from Master

Copy the kubeconfig file from the master node to your local machine.

On your local machine:
```bash
mkdir -p ~/.kube
scp user@<MASTER_IP>:/etc/rancher/rke2/rke2.yaml ~/.kube/config
```

**What this does**: Securely copies the cluster configuration file to your local machine.

### Step 3: Update Server Address

Edit the config file to use the master's IP instead of localhost.

```bash
nano ~/.kube/config
```

Find the line with `server: https://127.0.0.1:6443` and change it to:
```
server: https://<MASTER_IP>:6443
```

**What this does**: Updates the configuration to point to the actual master node IP instead of localhost.

### Step 4: Test Remote Access

```bash
kubectl get nodes
```

You should now be able to manage the cluster from your local machine.

## Troubleshooting

### Nodes Not Appearing

If worker nodes don't appear in the cluster:

1. Check agent logs:
   ```bash
   sudo journalctl -u rke2-agent -n 100
   ```

2. Verify the token is correct in `/etc/rancher/rke2/config.yaml`

3. Ensure the master node IP is reachable:
   ```bash
   ping <MASTER_IP>
   telnet <MASTER_IP> 9345
   ```

### Nodes in NotReady State

If nodes show "NotReady" status:

1. Check for pod network issues:
   ```bash
   kubectl get pods -n kube-system
   ```

2. Restart the service:
   ```bash
   sudo systemctl restart rke2-server  # On master
   sudo systemctl restart rke2-agent   # On workers
   ```

### Certificate Issues

If you see certificate errors:

1. Check system time is synchronized on all nodes:
   ```bash
   timedatectl
   ```

2. Install and configure NTP if needed:
   ```bash
   sudo apt install systemd-timesyncd
   sudo systemctl enable systemd-timesyncd
   sudo systemctl start systemd-timesyncd
   ```

### Port Connectivity Issues

Test if required ports are accessible:

```bash
# From worker to master
nc -zv <MASTER_IP> 9345
nc -zv <MASTER_IP> 6443
```

### Check Service Status

Verify RKE2 services are running:

```bash
# On master
sudo systemctl status rke2-server

# On workers
sudo systemctl status rke2-agent
```

### View Detailed Logs

For more detailed troubleshooting:

```bash
# On master
sudo journalctl -u rke2-server -n 200 --no-pager

# On workers
sudo journalctl -u rke2-agent -n 200 --no-pager
```

### Reset and Start Over

If you need to completely reset a node:

```bash
# On master
sudo /usr/local/bin/rke2-uninstall.sh

# On workers
sudo /usr/local/bin/rke2-agent-uninstall.sh
```

Then start the installation process again from the beginning.

## Additional Configuration

### High Availability Setup

For production environments, consider setting up multiple master nodes for high availability. This requires:

- At least 3 master nodes (odd number recommended)
- A load balancer in front of the master nodes
- Shared datastore or embedded etcd

### Storage Configuration

To use persistent storage in your cluster, you may need to:

- Install a CSI driver (like Longhorn for distributed storage)
- Configure NFS or other storage backends
- Set up StorageClasses for dynamic provisioning

### Ingress Controller

RKE2 comes with nginx ingress controller by default. To verify:

```bash
kubectl get pods -n kube-system | grep ingress
```

### Network Policy

RKE2 includes Canal (Calico + Flannel) for networking and network policy enforcement by default.

## Summary

You now have a fully functional 3-node RKE2 Kubernetes cluster with:

- 1 master node running the control plane
- 2 worker nodes for running workloads
- kubectl configured for cluster management
- All system components running and healthy

You can now deploy applications to this cluster using standard Kubernetes manifests, Helm charts, or GitOps tools like FluxCD.

## Next Steps

1. Deploy your first application
2. Set up monitoring with Prometheus and Grafana
3. Configure ingress for external access
4. Implement backup strategies for etcd
5. Set up CI/CD pipelines for automated deployments