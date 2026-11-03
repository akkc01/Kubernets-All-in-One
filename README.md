# ☸️ Kubernetes-AIO | Kubernetes All-in-One Learning Repository

\<p align="center">\
&#x20; \<img src="[https://img.shields.io/badge/Kubernetes-Learning-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white](https://img.shields.io/badge/Kubernetes-Learning-326CE5?style=for-the-badge\&logo=kubernetes\&logoColor=white)" />\
&#x20; \<img src="[https://img.shields.io/badge/Azure-AKS-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white](https://img.shields.io/badge/Azure-AKS-0078D4?style=for-the-badge\&logo=microsoftazure\&logoColor=white)" />\
&#x20; \<img src="[https://img.shields.io/badge/Docker-Containers-2496ED?style=for-the-badge&logo=docker&logoColor=white](https://img.shields.io/badge/Docker-Containers-2496ED?style=for-the-badge\&logo=docker\&logoColor=white)" />\
&#x20; \<img src="[https://img.shields.io/badge/Helm-Kubernetes%20Package%20Manager-0F1689?style=for-the-badge&logo=helm&logoColor=white](https://img.shields.io/badge/Helm-Kubernetes%20Package%20Manager-0F1689?style=for-the-badge\&logo=helm\&logoColor=white)" />\
&#x20; \<img src="[https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?style=for-the-badge\&logo=argo\&logoColor=white)" />\
\</p>

\<p align="center">\
&#x20; \<b>Learn Kubernetes from Fundamentals to Production-Level Implementation.\</b>\
\</p>

---

## 📌 About This Repository

Welcome to **Kubernetes-AIO (Kubernetes All-in-One)**!

This repository is a comprehensive, hands-on Kubernetes learning resource designed to help engineers understand Kubernetes concepts through practical implementation, YAML manifests, real-world scenarios, and troubleshooting exercises.

The goal is not just to learn Kubernetes commands but to understand how Kubernetes works internally and how to deploy, manage, secure, scale, and troubleshoot containerized applications in production environments.

Whether you are starting your Kubernetes journey or preparing for a DevOps, Cloud Engineer, or Kubernetes Administrator role, this repository provides a structured learning path.

## 🎯 Repository Objectives

- Understand Kubernetes architecture and core components.
- Build and manage Kubernetes clusters.
- Deploy and manage containerized applications.
- Understand Kubernetes networking and service discovery.
- Implement persistent storage using PV, PVC, and StorageClass.
- Configure workload scheduling using Taints, Tolerations, and Affinity.
- Implement autoscaling and resource management.
- Secure Kubernetes workloads using RBAC and Service Accounts.
- Implement application health checks and deployment strategies.
- Work with Azure Kubernetes Service (AKS).
- Configure Ingress and Gateway API.
- Implement monitoring and observability.
- Manage applications using Helm.
- Implement Azure Workload Identity.

---

## 📂 Repository Structure & Learning Modules

The repository is organized into practical modules, progressing from Kubernetes fundamentals to advanced production concepts.

| No. | Module                         | Topics Covered                                                           |
| --- | ------------------------------ | ------------------------------------------------------------------------ |
| 01  | Introduction                   | What is Kubernetes, architecture, components, core concepts              |
| 02  | Cluster Setup                  | Cluster installation, configuration, kubectl, KIND, AKS                  |
| 03  | Kubernetes Workloads           | Pods, Deployments, ReplicaSets, StatefulSets, DaemonSets, Jobs, CronJobs |
| 04  | Services                       | ClusterIP, NodePort, LoadBalancer, ExternalName                          |
| 05  | Network Policy                 | Pod-to-Pod communication, ingress and egress traffic control             |
| 06  | Configuration                  | ConfigMaps, Secrets, environment variables                               |
| 07  | Storage                        | PV, PVC, StorageClass, static and dynamic provisioning                   |
| 08  | Taints and Tolerations         | Node scheduling, taints, tolerations, NoSchedule, NoExecute              |
| 09  | Affinity and Anti-Affinity     | Node affinity, Pod affinity, Pod anti-affinity                           |
| 10  | HPA, ResourceQuota, LimitRange | Autoscaling, resource requests, limits, namespace quotas                 |
| 11  | RBAC and ServiceAccount        | Roles, ClusterRoles, RoleBindings, Service Accounts                      |
| 12  | Deployment Strategies          | Rolling updates, Recreate, Blue-Green, Canary deployments                |
| 13  | Health Probes                  | Liveness, Readiness, Startup probes                                      |
| 14  | AKS                            | Azure Kubernetes Service, node pools, Azure networking, private AKS      |
| 15  | Ingress                        | Ingress Controller, Ingress resources, host-based and path-based routing |
| 16  | Gateway API                    | GatewayClass, Gateway, HTTPRoute, backend traffic management             |
| 16  | Monitoring                     | Prometheus, Grafana, Loki, metrics and logs                              |
| 17  | Helm                           | Helm architecture, charts, templates, values, releases                   |
| 18  | Workload Identity              | Azure Workload Identity, Microsoft Entra ID, federated credentials       |

---

## 🏗️ Kubernetes Architecture

Kubernetes follows a control-plane and worker-node architecture.

### Control Plane

- **API Server:** Exposes the Kubernetes API.
- **etcd:** Stores cluster state and configuration.
- **Scheduler:** Schedules Pods onto suitable worker nodes.
- **Controller Manager:** Ensures the actual cluster state matches the desired state.
- **Cloud Controller Manager:** Integrates Kubernetes with cloud infrastructure.

### Worker Node

- **Kubelet:** Manages Pod lifecycle on the node.
- **Kube-proxy:** Implements Service networking rules where used.
- **Container Runtime:** Runs containers using containerd or another supported runtime.

---

## 🛠️ Technologies & Tools

This repository focuses on practical implementation using the following technologies:

| Technology               | Purpose                            |
| ------------------------ | ---------------------------------- |
| Kubernetes               | Container orchestration            |
| Docker                   | Containerization                   |
| kubectl                  | Kubernetes command-line management |
| KIND                     | Local Kubernetes cluster           |
| Azure Kubernetes Service | Managed Kubernetes                 |
| Azure Container Registry | Container image management         |
| Helm                     | Kubernetes package management      |
| ArgoCD                   | GitOps continuous delivery         |
| Prometheus               | Metrics collection                 |
| Grafana                  | Monitoring dashboards              |
| Loki                     | Log aggregation                    |
| Terraform                | Infrastructure provisioning        |
| Microsoft Entra ID       | Identity and access management     |

---

## 🚀 Getting Started

### Prerequisites

Before starting, make sure you have the following tools installed:

- Docker Desktop
- kubectl
- KIND or Minikube
- Helm
- Azure CLI (for AKS modules)
- Git

### Verify Installation

```
# Check Docker
docker version

# Check Kubernetes CLI
kubectl version --client

# Check Helm
helm version

# Check KIND
kind version

# Check Azure CLI
az version
```

### Clone This Repository

```
git clone https://github.com/<YOUR-USERNAME>/Kubernetes-AIO.git

cd Kubernetes-AIO
```

### Create a Local Kubernetes Cluster

```
kind create cluster --name kubernetes-aio

kubectl cluster-info

kubectl get nodes
```

### Verify Cluster

```
kubectl get nodes -o wide

kubectl get namespaces

kubectl get pods -A
```

---

## 🧪 Hands-on Learning Approach

Every module is designed around practical implementation.

The recommended workflow is:

1. Understand the Kubernetes concept.
2. Explore the YAML manifest.
3. Deploy the resources.
4. Verify the deployment.
5. Test the application.
6. Troubleshoot common errors.
7. Clean up the resources.

### Example: Deploy an Nginx Application

```
# Create namespace
kubectl create namespace demo

# Deploy Nginx
kubectl create deployment nginx \
  --image=nginx:latest \
  -n demo

# Verify deployment
kubectl get deployments -n demo

# Check Pods
kubectl get pods -n demo

# Expose application
kubectl expose deployment nginx \
  --type=NodePort \
  --port=80 \
  -n demo

# Check services
kubectl get svc -n demo
```

---

## ☁️ Kubernetes on Azure (AKS)

A dedicated module covers Azure Kubernetes Service and its production-oriented configurations.

Topics include:

- AKS Cluster Architecture
- System and User Node Pools
- Azure CNI
- Azure CNI Overlay
- Azure CNI Node Subnet
- Private AKS
- Network-Isolated AKS
- Azure Container Registry Integration
- Azure Load Balancer
- Azure Application Gateway
- Gateway API and Application Gateway for Containers
- Azure Disk and Azure Files
- Managed Identity
- Microsoft Entra ID Integration
- Azure Workload Identity
- Azure Monitor and Log Analytics

---

## 📊 Monitoring & Observability

Monitoring is essential for maintaining Kubernetes cluster health and application availability.

This repository covers:

- Prometheus – Metrics collection.
- Grafana – Dashboard visualization.
- Loki – Centralized log aggregation.
- Kubernetes Metrics – Node and Pod resource utilization.
- Application Monitoring – Workload health and performance.

---

## 🔐 Kubernetes Security

Security topics covered throughout the repository:

- RBAC and least-privilege access.
- Service Accounts.
- Kubernetes Secrets.
- Network Policies.
- Workload Identity.
- Secure workload configuration.
- Resource management and isolation.
- Identity integration with Microsoft Entra ID.

---

## 🎓 Who Should Use This Repository?

This repository is useful for:

- DevOps Engineers.
- Cloud Engineers.
- Kubernetes Administrators.
- Azure Cloud Engineers.
- Platform Engineers.
- Site Reliability Engineers (SRE).
- Developers learning cloud-native technologies.
- IT professionals preparing for Kubernetes interviews.

---

## 📖 Official Documentation

| Resource                 | Documentation                                                                                  |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| Kubernetes               | [https://kubernetes.io/docs/](https://kubernetes.io/docs/)                                     |
| Kubernetes Concepts      | [https://kubernetes.io/docs/concepts/](https://kubernetes.io/docs/concepts/)                   |
| kubectl                  | [https://kubernetes.io/docs/reference/kubectl/](https://kubernetes.io/docs/reference/kubectl/) |
| KIND                     | [https://kind.sigs.k8s.io/](https://kind.sigs.k8s.io/)                                         |
| Helm                     | [https://helm.sh/docs/](https://helm.sh/docs/)                                                 |
| Azure Kubernetes Service | [https://learn.microsoft.com/en-us/azure/aks/](https://learn.microsoft.com/en-us/azure/aks/)   |
| Gateway API              | [https://gateway-api.sigs.k8s.io/](https://gateway-api.sigs.k8s.io/)                           |
| Prometheus               | [https://prometheus.io/docs/](https://prometheus.io/docs/)                                     |
| Grafana                  | [https://grafana.com/docs/](https://grafana.com/docs/)                                         |
| ArgoCD                   | [https://argo-cd.readthedocs.io/](https://argo-cd.readthedocs.io/)                             |

---

## 📈 Learning Philosophy

**Learn → Implement → Validate → Troubleshoot → Master**

The focus of this repository is practical Kubernetes knowledge rather than memorizing commands.

Every module aims to build the skills required to operate Kubernetes workloads in real-world cloud and production environments.

---

## 🤝 Contributions

Contributions, suggestions, and improvements are welcome!

If you find this repository useful:

- ⭐ Star this repository.
- 🍴 Fork the project.
- 🐛 Report issues.
- 💡 Suggest improvements.
- 🤝 Submit pull requests.

---

## 👨‍💻 Author

**Amit Kumar Verma**

Cloud & DevOps Engineer | Azure | Kubernetes | Terraform | Docker | Helm | GitOps

GitHub: [@akkc01](https://github.com/akkc01)

---

\<p align="center">\
&#x20; \<b>☸️ Kubernetes-AIO\</b>\
&#x20; \<br/>\
&#x20; \<i>From Kubernetes Fundamentals to Production-Ready Cloud-Native Engineering.\</i>\
&#x20; \<br/>\<br/>\
&#x20; ⭐ If this repository helps you, consider giving it a star!\
\</p>
