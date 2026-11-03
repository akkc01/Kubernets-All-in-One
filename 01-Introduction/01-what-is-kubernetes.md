# ☸️ What is Kubernetes (K8s)?

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-Container%20Orchestration-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />
  <img src="https://img.shields.io/badge/Level-Beginner-2EA44F?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Category-Cloud%20Native-blue?style=for-the-badge" />
</p>

## 📌 1. Introduction to Kubernetes

**Kubernetes (K8s)** is an open-source container orchestration platform used to automate the deployment, scaling, management, and operation of containerized applications.

It was originally developed by Google and is now maintained by the Cloud Native Computing Foundation (CNCF).

Kubernetes helps organizations manage containerized applications across multiple servers by providing features such as:

- Automated deployment and scaling.
- Self-healing applications.
- Load balancing and service discovery.
- Rolling updates and rollbacks.
- Container scheduling.
- Storage orchestration.
- Configuration and secret management.
- Resource management.

**In simple terms:**

Kubernetes manages containers across multiple machines and ensures that applications run according to the desired configuration.

---

## 🤔 2. Why Do We Need Kubernetes?

Before understanding Kubernetes, let's understand a common problem in application deployment.

Imagine you have developed an application using Docker.

Initially, you have one container running on one server.

Everything works perfectly.

But as your application grows, several problems start appearing:

- What happens when the container crashes?
- How do you manage 100 containers?
- How do you distribute traffic across multiple containers?
- How do you scale applications when traffic increases?
- How do you deploy new application versions without downtime?
- How do you manage containers across multiple servers?

Managing everything manually becomes difficult.

This is where Kubernetes comes into the picture.

### Without Kubernetes

- Manually starting and stopping containers.
- Manually monitoring application health.
- Manually scaling containers.
- Manually managing application deployments.
- Manually handling container failures.

### With Kubernetes

- Automatically schedules containers.
- Restarts failed containers when required.
- Maintains the desired number of replicas.
- Supports automatic scaling.
- Provides service discovery and load balancing.
- Supports rolling updates and rollbacks.

---

## 🐳 3. What is Container Orchestration?

Container orchestration is the automated process of managing containerized applications across multiple machines.

It includes:

1. Container deployment.
2. Container scheduling.
3. Application scaling.
4. Container health monitoring.
5. Load balancing.
6. Networking.
7. Storage management.
8. Failure recovery.

Kubernetes is one of the most widely adopted container orchestration platforms.

### Popular Container Orchestration Platforms

| Platform | Description |
|---|---|
| Kubernetes | Open-source container orchestration platform. |
| Docker Swarm | Docker's native container orchestration solution. |
| Amazon ECS | AWS container orchestration service. |
| Azure Kubernetes Service | Microsoft's managed Kubernetes service. |
| Google Kubernetes Engine | Google's managed Kubernetes service. |

---

## 🏗️ 4. Kubernetes Architecture Overview

Kubernetes architecture is divided into two major components:

1. Control Plane.
2. Worker Nodes.

The Control Plane manages the cluster, while Worker Nodes execute application workloads.

### Kubernetes Architecture Diagram

```text
                  Kubernetes Cluster
                         |
             +-----------+-----------+
             |                       |
             v                       v
       CONTROL PLANE              WORKER NODES
             |                       |
      +------+-------+          +----+------+
      |      |       |          |           |
      v      v       v          v           v
   API     etcd  Scheduler   Kubelet    Kube-proxy
  Server                       |           |
      |                        v           |
      |                    Container      |
      |                    Runtime        |
      |                        |           |
      |                        v           |
      |                    +-------+       |
      |                    |  Pod  |       |
      |                    | App   |       |
      |                    +-------+       |
      |                                    |
      +------------------------------------+
```

### 4.1 Control Plane Components

The Control Plane manages the overall Kubernetes cluster.

| Component | Responsibility |
|---|---|
| API Server | Exposes Kubernetes API and handles cluster requests. |
| etcd | Stores cluster state and configuration data. |
| Scheduler | Assigns newly created Pods to suitable worker nodes. |
| Controller Manager | Runs controllers that maintain the desired cluster state. |
| Cloud Controller Manager | Integrates Kubernetes with cloud provider infrastructure. |

### 4.2 Worker Node Components

Worker Nodes are responsible for running application workloads.

| Component | Responsibility |
|---|---|
| Kubelet | Ensures Pods and their containers run according to Pod specifications. |
| Kube-proxy | Implements Service networking rules when used by the network implementation. |
| Container Runtime | Runs containers, such as containerd or CRI-O. |

---

## ⚙️ 5. How Does Kubernetes Work?

Kubernetes follows a **Declarative Configuration Model**.

This means you tell Kubernetes what you want, and Kubernetes continuously works to achieve that desired state.

### Example

Suppose you want to run an Nginx application with three replicas.

You define the desired configuration:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: nginx-deployment

spec:
  replicas: 3

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
          image: nginx:latest
          ports:
            - containerPort: 80
```

Kubernetes will:

1. Receive the Deployment configuration through the API Server.
2. Store the cluster state in etcd.
3. Use the Deployment and ReplicaSet controllers to create the required Pods.
4. Ask the Scheduler to assign unscheduled Pods to suitable nodes.
5. Kubelet instructs the container runtime to start the containers.
6. Continuously monitor and reconcile the actual state against the desired state.

### What if a Pod crashes?

Suppose you have three Nginx Pods running.

One Pod crashes.

Kubernetes detects that the actual number of available replicas is below the desired number and attempts to restore the desired state.

**Desired State:** 3 replicas.

**Actual State:** 2 replicas.

**Kubernetes Action:** Reconcile the workload to restore three replicas.

This process is called **Reconciliation**.

---

## 📦 6. What is a Pod?

A Pod is the smallest deployable unit in Kubernetes.

A Pod can contain one or more containers that share:

- Network namespace and IP address.
- Port space.
- Storage volumes.
- A lifecycle managed by Kubernetes.

Most applications use one main application container per Pod.

Example:

```text
       Kubernetes Cluster
               |
               v
             Node
               |
               v
             Pod
               |
        +-------------+
        |             |
        v             v
    Container 1   Container 2
      Nginx         Sidecar
```

---

## 🧩 7. Important Kubernetes Objects

Kubernetes uses different resources to manage application workloads and infrastructure.

| Object | Purpose |
|---|---|
| Pod | Runs one or more containers. |
| Deployment | Manages stateless application workloads. |
| ReplicaSet | Maintains the required number of Pod replicas. |
| StatefulSet | Manages stateful workloads with stable identities. |
| DaemonSet | Runs Pods on selected nodes. |
| Job | Runs tasks until completion. |
| CronJob | Executes scheduled tasks. |
| Service | Provides stable network access to Pods. |
| Ingress | Manages HTTP/HTTPS traffic routing. |
| Gateway API | Provides advanced traffic management. |
| ConfigMap | Stores non-sensitive configuration. |
| Secret | Stores sensitive configuration data. |
| Namespace | Provides logical resource isolation. |
| PersistentVolume | Represents storage resources. |
| PersistentVolumeClaim | Requests storage resources. |
| StorageClass | Defines storage provisioning policies. |

---

## 🚀 8. Key Features of Kubernetes

### 8.1 Self-Healing

Kubernetes can restart failed containers, replace failed Pods managed by controllers, and maintain the desired number of replicas.

### 8.2 Auto Scaling

Kubernetes supports automatic scaling based on resource utilization and other metrics.

Examples:

- Horizontal Pod Autoscaler (HPA).
- Vertical Pod Autoscaler (VPA).
- Cluster Autoscaler.

### 8.3 Load Balancing

Kubernetes Services provide stable access to application Pods and distribute traffic across eligible endpoints.

### 8.4 Rolling Updates

Kubernetes supports updating application versions gradually without requiring all application instances to stop simultaneously.

### 8.5 Rollbacks

If a deployment update causes problems, you can roll back to a previous revision.

### 8.6 Service Discovery

Applications can communicate with Kubernetes Services using DNS names.

### 8.7 Storage Orchestration

Kubernetes integrates with different storage systems through PersistentVolumes, PersistentVolumeClaims, and StorageClasses.

---

## 🌐 9. Kubernetes Networking Overview

Kubernetes networking enables communication between different components.

Important networking concepts:

- Pod-to-Pod communication.
- Pod-to-Service communication.
- Service-to-Service communication.
- External-to-Pod communication.
- Cluster DNS.
- Network Policies.
- Container Network Interface (CNI).

### Kubernetes Service Types

| Service Type | Description |
|---|---|
| ClusterIP | Exposes an application internally within the cluster. |
| NodePort | Exposes a Service through a port on cluster nodes. |
| LoadBalancer | Exposes a Service using an external load balancer. |
| ExternalName | Maps a Service to an external DNS name. |

---

## ☁️ 10. Kubernetes in Cloud Environments

Kubernetes can run on-premises, in virtual machines, and on cloud infrastructure.

Major managed Kubernetes services include:

| Cloud Provider | Managed Kubernetes Service |
|---|---|
| Microsoft Azure | Azure Kubernetes Service (AKS) |
| Amazon Web Services | Elastic Kubernetes Service (EKS) |
| Google Cloud | Google Kubernetes Engine (GKE) |

### Example: Azure Kubernetes Service (AKS)

AKS is Microsoft's managed Kubernetes service.

It simplifies Kubernetes cluster management by providing:

- Managed Kubernetes Control Plane.
- Worker Node Pools.
- Azure Networking Integration.
- Azure Container Registry Integration.
- Microsoft Entra ID Integration.
- Azure Monitor Integration.
- Azure Disk and Azure Files Integration.
- Managed Identity and Workload Identity.

---

## 🏢 11. Real-World Kubernetes Use Cases

Kubernetes is commonly used in:

**Microservices Architecture**

Deploy and manage multiple independent microservices.

**E-commerce Applications**

Scale application components during high traffic periods.

**Banking Applications**

Deploy containerized services with controlled access, availability, and security.

**CI/CD Pipelines**

Automate application deployments using tools such as Jenkins, GitHub Actions, and Azure DevOps.

**Machine Learning Platforms**

Run containerized machine learning workloads and distributed processing jobs.

**Cloud-Native Applications**

Build, deploy, and manage modern distributed applications.

---

## ⚖️ 12. Advantages and Disadvantages

### Advantages

- Automated application deployment.
- High availability capabilities.
- Application self-healing.
- Horizontal scaling.
- Efficient resource utilization.
- Portable container orchestration.
- Declarative configuration.
- Large open-source ecosystem.

### Disadvantages

- Initial learning curve can be steep.
- Cluster management can be complex.
- Requires networking and storage knowledge.
- Troubleshooting distributed applications can be challenging.
- Operational overhead for self-managed clusters.
- Not always necessary for small or simple applications.

---

## 🧪 13. Hands-on Practice

Let's deploy our first application using Kubernetes.

### Step 1: Verify Kubernetes Cluster

```bash
kubectl cluster-info

kubectl get nodes
```

### Step 2: Create a Namespace

```bash
kubectl create namespace demo
```

### Step 3: Deploy Nginx

```bash
kubectl create deployment nginx \
  --image=nginx:latest \
  --replicas=3 \
  -n demo
```

### Step 4: Verify Pods

```bash
kubectl get pods -n demo
```

### Step 5: Expose the Application

```bash
kubectl expose deployment nginx \
  --type=NodePort \
  --port=80 \
  -n demo
```

### Step 6: Verify Service

```bash
kubectl get services -n demo
```

### Step 7: Check Deployment Details

```bash
kubectl describe deployment nginx -n demo
```

### Step 8: Scale the Application

```bash
kubectl scale deployment nginx \
  --replicas=5 \
  -n demo
```

### Step 9: Verify Scaling

```bash
kubectl get pods -n demo
```

### Step 10: Cleanup

```bash
kubectl delete namespace demo
```

---

## 🎤 14. Kubernetes Interview Questions

1. What is Kubernetes?
2. Why do we need Kubernetes?
3. What is container orchestration?
4. Explain Kubernetes architecture.
5. What is the difference between Control Plane and Worker Node?
6. What is a Pod?
7. What is the difference between a Pod and a Container?
8. What is the role of API Server?
9. What is etcd?
10. What is the role of kube-scheduler?
11. What is the difference between Deployment and StatefulSet?
12. How does Kubernetes perform self-healing?
13. What happens when a Pod crashes?
14. What is the difference between desired state and actual state?
15. What is the difference between Kubernetes and Docker?

---

## 📚 15. Official Documentation

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Kubernetes Workloads](https://kubernetes.io/docs/concepts/workloads/)
- [Kubernetes Networking](https://kubernetes.io/docs/concepts/services-networking/)
- [Kubernetes Storage](https://kubernetes.io/docs/concepts/storage/)
- [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)

---

## 🎯 16. Key Takeaways

- Kubernetes is a container orchestration platform.
- It automates deployment, scaling, and management of containerized applications.
- A Kubernetes cluster consists of a Control Plane and Worker Nodes.
- Pods are the smallest deployable units.
- Kubernetes follows a declarative configuration model.
- Controllers continuously reconcile actual state with desired state.
- Kubernetes supports self-healing, service discovery, load balancing, and scaling.
- AKS, EKS, and GKE provide managed Kubernetes services.

---

<p align="center">
  <b>☸️ Learn Kubernetes | Practice Kubernetes | Master Kubernetes</b>
  <br/><br/>
  <i>Understanding Kubernetes is the foundation of modern Cloud-Native and DevOps Engineering.</i>
</p>