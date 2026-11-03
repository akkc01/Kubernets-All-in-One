# Azure Kubernetes Service (AKS) -

## 1. Introduction

Azure Kubernetes Service (AKS) is a managed Kubernetes service provided by Microsoft Azure. It simplifies deploying, managing, and scaling containerized applications using Kubernetes.

With AKS, Microsoft manages important Kubernetes control-plane components, allowing engineers to focus on application deployment, cluster configuration, networking, security, and operations.

### Key Features

- Managed Kubernetes control plane.
- Automatic Kubernetes version upgrades.
- Node pools for workload isolation.
- Azure CNI and kubenet networking options.
- Integration with Azure Container Registry (ACR).
- Integration with Azure Monitor and Log Analytics.
- Microsoft Entra ID authentication.
- Autoscaling and self-healing capabilities.
- Private cluster support.

## 2. Architecture Overview

An AKS cluster consists of a managed control plane and one or more node pools.

```text
                   Azure Cloud
                       |
                Resource Group
                       |
                  AKS Cluster
                       |
             +---------+---------+
             |                   |
       Control Plane         Node Pool
       (Managed by Azure)        |
             |              Worker Nodes
       +-----+-----+          |
       |           |      +---+----------+
    API Server  Scheduler  |              |
                       Node 1          Node 2
                         |               |
                    +----+----+     +----+----+
                    |         |     |         |
                   Pod      Pod   Pod       Pod
                    |         |     |         |
                    +---------+-----+---------+
                              |
                         Kubernetes
                          Services
```

### Control Plane Components

| Component | Responsibility |
|---|---|
| API Server | Exposes the Kubernetes API |
| Scheduler | Assigns Pods to worker nodes |
| Controller Manager | Maintains the desired cluster state |
| etcd | Stores Kubernetes cluster state |

In AKS, the control plane is managed by Azure. You generally interact with it through the Kubernetes API using `kubectl`.

### Worker Node Components

| Component | Responsibility |
|---|---|
| kubelet | Ensures Pods are running on the node |
| kube-proxy | Implements Service networking where applicable |
| Container Runtime | Runs containers, typically containerd |
| Pods | Run application workloads |

## 3. Prerequisites

Before creating an AKS cluster, make sure you have:

- An active Azure subscription.
- An Azure resource group.
- Azure CLI installed.
- kubectl installed.
- Sufficient permissions to create AKS and associated Azure resources.

### Install Azure CLI

For macOS:

```bash
brew update
brew install azure-cli
```

Verify:

```bash
az version
```

### Install kubectl

```bash
az aks install-cli
```

Verify:

```bash
kubectl version --client
```

## 4. Create an AKS Cluster Using Azure Portal

This section explains how to create an AKS cluster through the Azure Portal GUI.

### Step 1: Open Azure Portal

Navigate to:

https://portal.azure.com

Search for **Kubernetes services** and select **Create → Kubernetes cluster**.

### Step 2: Configure Basic Settings

Under the Basics tab, configure the following:

| Setting | Example Value |
|---|---|
| Subscription | Your Azure Subscription |
| Resource Group | rg-aks-demo |
| Cluster Name | aks-demo-cluster |
| Region | Choose a nearby Azure region |
| Kubernetes Version | Select a supported version |
| Automatic Upgrade | Configure as required |
| Node Pool | System |
| Node Count | 2 |
| Node Size | Choose an appropriate VM SKU |

**Note:** Node size and availability depend on your Azure region, subscription quota, and capacity.

### Step 3: Configure Node Pools

A node pool is a group of Kubernetes nodes with the same configuration.

For a basic learning cluster:

- Node pool name: `systempool`
- Mode: System
- Node count: 2
- Enable cluster autoscaler only if required for your lab.

You can add additional user node pools later for application workloads.

### Step 4: Configure Networking

Choose the networking configuration.

Common options:

| Networking | Description |
|---|---|
| Azure CNI Overlay | Assigns Pod IPs from an overlay address range |
| Azure CNI Pod Subnet | Uses a separate subnet for Pod IP allocation |
| Azure CNI Node Subnet | Allocates Pod IPs from the node subnet |
| Kubenet | Legacy networking option; avoid for new designs unless required |

For a learning environment, Azure CNI Overlay is a useful option.

Configure the DNS name prefix and network settings as required.

### Step 5: Configure Integrations

You can configure:

- Azure Monitor
- Container Insights
- Microsoft Entra ID authentication
- Azure Policy
- Azure Container Registry integration

For a basic lab, enable monitoring if your budget allows.

### Step 6: Review and Create

1. Click **Review + create**.
2. Wait for Azure validation.
3. Click **Create**.
4. Wait for deployment to complete.
5. Open the AKS resource after deployment.

Your AKS cluster is now provisioned.

## 5. Create an AKS Cluster Using Azure CLI

You can also create the cluster using Azure CLI.

### Step 1: Login to Azure

```bash
az login
```

List subscriptions:

```bash
az account list --output table
```

Select your subscription:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
```

Verify:

```bash
az account show --output table
```

### Step 2: Create a Resource Group

```bash
az group create \
  --name rg-aks-demo \
  --location centralindia
```

### Step 3: Create an AKS Cluster

```bash
az aks create \
  --resource-group rg-aks-demo \
  --name aks-demo-cluster \
  --location centralindia \
  --node-count 2 \
  --node-vm-size Standard_D2s_v5 \
  --generate-ssh-keys \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --pod-cidr 10.244.0.0/16
```

**Important:**

- Check regional VM SKU availability and subscription quota before running this command.
- The Pod CIDR must not overlap with connected networks.
- This is a learning-oriented cluster configuration, not a production baseline.
- Cluster creation may take several minutes.

### Step 4: Verify AKS Cluster

```bash
az aks list \
  --resource-group rg-aks-demo \
  --output table
```

Get cluster details:

```bash
az aks show \
  --resource-group rg-aks-demo \
  --name aks-demo-cluster \
  --output table
```

## 6. Connect to AKS Using kubectl

After cluster creation, configure your local Kubernetes context.

### Step 1: Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group rg-aks-demo \
  --name aks-demo-cluster
```

This merges the AKS credentials into your local kubeconfig file.

### Step 2: Verify Kubernetes Context

```bash
kubectl config get-contexts
```

Check the current context:

```bash
kubectl config current-context
```

### Step 3: Verify Cluster Connectivity

```bash
kubectl cluster-info
```

Check nodes:

```bash
kubectl get nodes -o wide
```

Check system Pods:

```bash
kubectl get pods -n kube-system
```

Expected node status:

```text
NAME                                STATUS   ROLES
aks-systempool-xxxx-vmss000000      Ready    <none>
aks-systempool-xxxx-vmss000001      Ready    <none>
```

Node names will differ in your environment.

## 7. Deploy an NGINX Application on AKS

Let's deploy a simple NGINX application to verify that the cluster is working.

### Step 1: Create a Namespace

```bash
kubectl create namespace aks-demo
```

Verify:

```bash
kubectl get namespaces
```

### Step 2: Create Deployment YAML

Create a file named `nginx-deployment.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: aks-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

### Step 3: Deploy the Application

```bash
kubectl apply -f nginx-deployment.yaml
```

Verify:

```bash
kubectl get deployments -n aks-demo
```

Check Pods:

```bash
kubectl get pods -n aks-demo -o wide
```

### Step 4: Create a Service

Create `nginx-service.yaml`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: aks-demo
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```

Apply:

```bash
kubectl apply -f nginx-service.yaml
```

### Step 5: Verify the Service

```bash
kubectl get svc -n aks-demo
```

A `LoadBalancer` Service normally provisions an Azure Load Balancer frontend and public IP when the cluster is configured for that integration.

Check the external IP:

```bash
kubectl get svc nginx-service -n aks-demo -w
```

Once an external IP is assigned, open:

```text
http://<EXTERNAL-IP>
```

You should see the NGINX welcome page.

**Note:** Provisioning the public IP can take a few minutes. Network policies, NSGs, firewall rules, or private-cluster configurations may affect accessibility.

## 8. Useful AKS Commands

### Cluster Information

```bash
az aks show -g rg-aks-demo -n aks-demo-cluster -o table
```

### List Nodes

```bash
kubectl get nodes -o wide
```

### List All Pods

```bash
kubectl get pods -A
```

### List Services

```bash
kubectl get services -A
```

### Describe a Pod

```bash
kubectl describe pod <POD_NAME> -n aks-demo
```

### View Pod Logs

```bash
kubectl logs <POD_NAME> -n aks-demo
```

### Execute Commands Inside a Container

```bash
kubectl exec -it <POD_NAME> -n aks-demo -- /bin/sh
```

### View Cluster Events

```bash
kubectl get events -A --sort-by=.metadata.creationTimestamp
```

## 9. AKS Node Pool Management

Node pools allow you to separate system components from application workloads.

### List Node Pools

```bash
az aks nodepool list \
  --resource-group rg-aks-demo \
  --cluster-name aks-demo-cluster \
  --output table
```

### Create a User Node Pool

```bash
az aks nodepool add \
  --resource-group rg-aks-demo \
  --cluster-name aks-demo-cluster \
  --name userpool \
  --mode User \
  --node-count 2 \
  --node-vm-size Standard_D2s_v5
```

### Verify Node Pools

```bash
az aks nodepool list \
  -g rg-aks-demo \
  --cluster-name aks-demo-cluster \
  -o table
```

### Scale a Node Pool

```bash
az aks nodepool scale \
  --resource-group rg-aks-demo \
  --cluster-name aks-demo-cluster \
  --name userpool \
  --node-count 3
```

## 10. Integrate AKS with Azure Container Registry (ACR)

Azure Container Registry stores container images privately.

### Step 1: Create ACR

```bash
az acr create \
  --resource-group rg-aks-demo \
  --name <UNIQUE_ACR_NAME> \
  --sku Basic
```

ACR names must be globally unique and contain only supported characters.

### Step 2: Attach ACR to AKS

```bash
az aks update \
  --resource-group rg-aks-demo \
  --name aks-demo-cluster \
  --attach-acr <UNIQUE_ACR_NAME>
```

This grants the AKS kubelet identity permission to pull images from ACR using the supported role assignment.

### Step 3: Verify ACR Integration

```bash
az aks show \
  --resource-group rg-aks-demo \
  --name aks-demo-cluster \
  --query "identity"
```

You can now reference images from your ACR in Kubernetes Deployment manifests.

Example:

```yaml
containers:
  - name: myapp
    image: <UNIQUE_ACR_NAME>.azurecr.io/myapp:v1
```

## 11. AKS Monitoring and Troubleshooting

### Check Node Status

```bash
kubectl get nodes
```

### Check Pod Status

```bash
kubectl get pods -A
```

### Inspect Pod Events

```bash
kubectl describe pod <POD_NAME> -n <NAMESPACE>
```

### Check Logs

```bash
kubectl logs <POD_NAME> -n <NAMESPACE>
```

### Common Issues

| Issue | Possible Cause | Troubleshooting |
|---|---|---|
| ImagePullBackOff | Invalid image or missing registry permissions | Check image name and ACR access |
| CrashLoopBackOff | Application startup failure | Inspect container logs |
| Pending Pod | Insufficient resources or scheduling constraints | Describe the Pod and inspect events |
| LoadBalancer Pending | Azure provisioning or quota issue | Inspect Service events and Azure resources |
| Node NotReady | Node or network problem | Inspect node conditions and AKS diagnostics |

Useful Azure CLI command:

```bash
az aks show \
  --resource-group rg-aks-demo \
  --name aks-demo-cluster \
  --query "provisioningState"
```

## 12. Clean Up Resources

To avoid unnecessary Azure charges, delete the lab resources when finished.

Delete the Kubernetes namespace:

```bash
kubectl delete namespace aks-demo
```

Delete the complete resource group:

```bash
az group delete \
  --name rg-aks-demo \
  --yes \
  --no-wait
```

**Warning:** Deleting the resource group also deletes the AKS cluster and other resources contained in it.

## 13. Hands-On Practice Labs

Complete these exercises to gain practical AKS experience.

| Lab | Task |
|---|---|
| Lab 1 | Create an AKS cluster using Azure Portal |
| Lab 2 | Create an AKS cluster using Azure CLI |
| Lab 3 | Connect to AKS using kubectl |
| Lab 4 | Deploy an NGINX application |
| Lab 5 | Expose an application using LoadBalancer |
| Lab 6 | Create a separate user node pool |
| Lab 7 | Scale a node pool |
| Lab 8 | Integrate AKS with ACR |
| Lab 9 | Deploy an application from ACR |
| Lab 10 | Configure Azure Monitor for containers |

## 14. Interview Questions

1. What is Azure Kubernetes Service?
2. What is the difference between AKS and self-managed Kubernetes?
3. Which Kubernetes components are managed by Azure in AKS?
4. What is a node pool in AKS?
5. What is the difference between System and User node pools?
6. What is Azure CNI Overlay?
7. What is the difference between Azure CNI Overlay and Azure CNI Node Subnet?
8. How does AKS integrate with Azure Container Registry?
9. How do you connect to a private AKS cluster?
10. How do you scale an AKS node pool?
11. What is the difference between Cluster Autoscaler and Horizontal Pod Autoscaler?
12. How do you monitor AKS?
13. How do you troubleshoot an ImagePullBackOff error?
14. What is the difference between a public and private AKS cluster?
15. How do you secure an AKS cluster?

## 15. Official Documentation

- [Azure Kubernetes Service Documentation](https://learn.microsoft.com/azure/aks/)
- [Create an AKS Cluster](https://learn.microsoft.com/azure/aks/learn/quick-kubernetes-deploy-cli)
- [AKS Networking Concepts](https://learn.microsoft.com/azure/aks/concepts-network)
- [AKS Node Pools](https://learn.microsoft.com/azure/aks/create-node-pools)
- [AKS and Azure Container Registry](https://learn.microsoft.com/azure/aks/cluster-container-registry-integration)
- [AKS Monitoring](https://learn.microsoft.com/azure/aks/monitor-aks)

---

## Conclusion

Azure Kubernetes Service provides a managed Kubernetes platform for running containerized workloads on Azure.

By completing this guide, you have learned how to:

- Create an AKS cluster using Azure Portal and Azure CLI.
- Configure Kubernetes access using kubectl.
- Deploy and expose an NGINX application.
- Manage node pools.
- Integrate AKS with Azure Container Registry.
- Troubleshoot common cluster issues.

**Next Step:** Explore AKS networking, storage, ingress, security, monitoring, and production-ready cluster architecture.