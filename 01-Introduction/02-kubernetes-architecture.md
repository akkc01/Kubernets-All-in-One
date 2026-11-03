# ☸️ Kubernetes Architecture

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-Architecture-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />
  <img src="https://img.shields.io/badge/Level-Beginner%20to%20Advanced-2EA44F?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Category-Cloud%20Native-blue?style=for-the-badge" />
</p>

## 📌 1. Introduction

Kubernetes follows a distributed architecture consisting of multiple components working together to manage containerized applications.

A Kubernetes cluster is primarily divided into two major components:

1. **Control Plane:** Responsible for managing and maintaining the overall Kubernetes cluster.
2. **Worker Nodes:** Responsible for running containerized applications inside Pods.

The Control Plane makes decisions about the cluster, while Worker Nodes execute the workloads.

Kubernetes uses a declarative model in which users define the desired state, and Kubernetes continuously works to maintain that state.

---

## 🏗️ 2. Kubernetes Cluster Architecture

A Kubernetes cluster consists of a Control Plane and one or more Worker Nodes.

### Architecture Diagram

```text
                       KUBERNETES CLUSTER
                              |
              +---------------+----------------+
              |                                |
              v                                v
        CONTROL PLANE                     WORKER NODES
              |                                |
     +--------+---------+             +--------+---------+
     |        |         |             |                  |
     v        v         v             v                  v
 API Server  etcd   Scheduler      Kubelet            Kube-proxy
     |                              |                  |
     |                              v                  |
     |                        Container Runtime        |
     |                              |                  |
     |                              v                  |
     |                         +---------+             |
     |                         |   Pod   |             |
     |                         |         |             |
     |                         | Nginx   |             |
     |                         +---------+             |
     |                                                 |
     +-------------------------------------------------+
```

### Component Overview

| Component | Location | Responsibility |
|---|---|---|
| API Server | Control Plane | Handles Kubernetes API requests. |
| etcd | Control Plane | Stores cluster state and configuration. |
| Scheduler | Control Plane | Selects nodes for unscheduled Pods. |
| Controller Manager | Control Plane | Runs controllers to maintain desired state. |
| Cloud Controller Manager | Control Plane (when used) | Integrates with cloud infrastructure. |
| Kubelet | Worker Node | Manages Pod lifecycle on the node. |
| Kube-proxy | Worker Node (when used) | Implements Service networking rules. |
| Container Runtime | Worker Node | Runs containers. |

---

# 🎛️ 3. Control Plane Components

The Control Plane is the brain of the Kubernetes cluster.

It manages cluster state, schedules workloads, and ensures that the actual state matches the desired state.

There are five major components to understand.

## 3.1 API Server (kube-apiserver)

The Kubernetes API Server is the primary communication interface for the Kubernetes cluster.

All Kubernetes API operations pass through the API Server.

It acts as the central entry point for:

- kubectl commands.
- Kubernetes Dashboard.
- CI/CD pipelines.
- Controllers.
- Scheduler.
- Kubelet.
- External automation tools.

### Responsibilities

1. Exposes Kubernetes REST APIs.
2. Authenticates incoming requests.
3. Authorizes user and service permissions.
4. Performs admission control.
5. Validates Kubernetes objects.
6. Reads and writes cluster state through etcd.

### Example

When you execute:

```bash
kubectl get pods
```

The following happens:

1. kubectl sends an API request to the API Server.
2. API Server authenticates the request.
3. API Server checks authorization.
4. The API Server retrieves the requested Pod information.
5. The response is returned to kubectl.

### API Server Communication

```text
       Administrator
             |
             v
          kubectl
             |
             v
        API SERVER
             |
       +-----+------+
       |            |
       v            v
     etcd       Controllers
                    |
                    v
                 Scheduler
```

### Important Commands

```bash
# Check API Server Pod
kubectl get pods -n kube-system

# Get API Server endpoint
kubectl cluster-info

# View API resources
kubectl api-resources

# View API versions
kubectl api-versions
```

---

## 3.2 etcd

**etcd** is a distributed, consistent key-value store used by Kubernetes to store cluster state and configuration data.

It is one of the most critical components of Kubernetes architecture.

### What Does etcd Store?

- Kubernetes object definitions.
- Pod metadata.
- Deployment configurations.
- Service configurations.
- Namespace information.
- Secrets and ConfigMaps.
- Cluster configuration and state.

etcd stores the Kubernetes API's persistent cluster data.

### How Does etcd Work?

Whenever Kubernetes resources are created, updated, or deleted through the API Server, the corresponding state changes are persisted in etcd.

Example:

```bash
kubectl create deployment nginx --image=nginx
```

Simplified workflow:

```text
       kubectl
          |
          v
      API Server
          |
          v
      Validation
          |
          v
         etcd
          |
          v
    Persistent State
```

### Important Points

- etcd uses a distributed consensus algorithm called Raft.
- It provides strong consistency for cluster data.
- It supports snapshots and backup operations.
- It should be secured using authentication and encryption.
- Production clusters require a reliable backup strategy.

### Important Commands

For clusters where etcd is accessible:

```bash
etcdctl endpoint health

etcdctl endpoint status

etcdctl member list
```

Note: In managed Kubernetes services such as AKS, EKS, and GKE, etcd is managed by the cloud provider and is generally not directly accessible to cluster users.

---

## 3.3 kube-scheduler

The Kubernetes Scheduler is responsible for selecting a suitable Worker Node for newly created Pods that do not have an assigned node.

It does not directly run containers.

Instead, it evaluates available nodes and selects an appropriate placement for each Pod.

### Scheduler Responsibilities

- Evaluate available Worker Nodes.
- Check CPU and memory availability.
- Consider resource requests.
- Evaluate node selectors.
- Consider node affinity and anti-affinity.
- Respect taints and tolerations.
- Consider topology and scheduling constraints.
- Select the most suitable node.

### Scheduling Workflow

```text
       Deployment Created
               |
               v
          ReplicaSet
               |
               v
          Pod Created
               |
               v
       API Server / etcd
               |
               v
        kube-scheduler
               |
               v
       Evaluate Worker Nodes
               |
        +------+------+
        |             |
        v             v
      Node-1        Node-2
        |             |
        +------+------+
               |
               v
        Select Suitable Node
               |
               v
       Bind Pod to Node
               |
               v
         Kubelet Starts Pod
```

### Example: Node Selector

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: nginx-pod

spec:
  nodeSelector:
    disktype: ssd

  containers:
    - name: nginx
      image: nginx:latest
```

Label a Worker Node:

```bash
kubectl label nodes worker-node-1 disktype=ssd
```

Deploy the Pod:

```bash
kubectl apply -f nginx-pod.yaml
```

Verify scheduling:

```bash
kubectl get pods -o wide
```

The Scheduler will consider nodes matching the requested label, along with other scheduling constraints.

---

## 3.4 kube-controller-manager

The Controller Manager runs Kubernetes controllers that continuously monitor the cluster and reconcile actual state with desired state.

A controller watches Kubernetes resources and takes corrective action when necessary.

### Important Controllers

| Controller | Responsibility |
|---|---|
| Node Controller | Monitors node health and availability. |
| Deployment Controller | Manages Deployment objects. |
| ReplicaSet Controller | Maintains the required number of Pod replicas. |
| Job Controller | Manages Job execution. |
| Namespace Controller | Handles namespace lifecycle. |
| EndpointSlice Controller | Maintains EndpointSlice resources. |
| ServiceAccount Controller | Manages ServiceAccount-related resources. |

### Example: ReplicaSet Controller

Suppose you create a Deployment with three replicas.

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: nginx

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
```

Check the Pods:

```bash
kubectl get pods
```

Initially:

```text
NAME                     READY   STATUS
nginx-abc123-1            1/1     Running
nginx-abc123-2            1/1     Running
nginx-abc123-3            1/1     Running
```

Delete one Pod:

```bash
kubectl delete pod nginx-abc123-1
```

The ReplicaSet Controller detects that only two replicas remain and creates a replacement Pod.

**Desired State:** 3 replicas.

**Actual State:** 2 replicas.

**Controller Action:** Create another Pod.

This is called the reconciliation loop.

---

## 3.5 Cloud Controller Manager

The Cloud Controller Manager integrates Kubernetes with cloud provider infrastructure.

It allows Kubernetes to communicate with cloud services and manage cloud-specific resources.

### Responsibilities

- Cloud node information.
- Cloud route management, where supported.
- Cloud load balancer provisioning.
- Cloud-specific node lifecycle management.

### Example: Azure Kubernetes Service

In AKS, cloud integration can help provision Azure infrastructure resources such as:

- Azure Load Balancer.
- Public IP addresses.
- Networking resources.
- Cloud-backed storage integrations.

The exact integration depends on the configured Azure cloud provider and storage drivers.

---

# 🖥️ 4. Worker Node Components

Worker Nodes are the machines where application workloads actually run.

A Worker Node can be a physical server or a virtual machine.

Every Kubernetes Worker Node requires a container runtime and kubelet. Kube-proxy is commonly used, but alternative networking implementations can provide Service networking without kube-proxy.

## 4.1 Kubelet

Kubelet is an agent that runs on each Worker Node.

It communicates with the API Server and ensures that the Pods assigned to its node are running according to their specifications.

### Responsibilities

- Watches for Pod assignments.
- Starts and stops containers through the container runtime.
- Monitors container health.
- Reports node and Pod status.
- Manages Pod volumes.
- Executes configured container probes.
- Reports node resource information.

### Kubelet Workflow

```text
          API Server
               |
               v
            Kubelet
               |
               v
       Container Runtime
               |
               v
        Create Containers
               |
               v
            Run Pod
               |
               v
        Report Pod Status
               |
               v
          API Server
```

### Important Commands

On a Linux node:

```bash
systemctl status kubelet

journalctl -u kubelet -f
```

---

## 4.2 Kube-proxy

Kube-proxy is responsible for implementing Kubernetes Service networking rules on nodes when the cluster uses kube-proxy.

It helps route traffic to the appropriate backend Pod endpoints.

### Responsibilities

- Implements Service virtual IP forwarding.
- Maintains network rules.
- Routes traffic to Service endpoints.
- Supports different proxy modes.

### Proxy Modes

| Mode | Description |
|---|---|
| iptables | Implements Service routing using iptables rules. |
| IPVS | Uses Linux IP Virtual Server functionality. |
| nftables | Uses Linux nftables for Service traffic handling. |

### Service Traffic Flow

```text
         Client Pod
              |
              v
       Kubernetes Service
          ClusterIP
              |
              v
          Node Rules
              |
        +-----+-----+
        |           |
        v           v
      Pod-1       Pod-2
```

**Important:** Kube-proxy is not mandatory in every Kubernetes cluster. Some networking implementations provide equivalent Service forwarding functionality without it.

---

## 4.3 Container Runtime

A Container Runtime is responsible for running containers on Worker Nodes.

Kubernetes communicates with the container runtime through the Container Runtime Interface (CRI).

### Popular Container Runtimes

| Runtime | Description |
|---|---|
| containerd | Industry-standard container runtime commonly used with Kubernetes. |
| CRI-O | Lightweight runtime designed specifically for Kubernetes. |

Docker Engine is not directly supported as a CRI runtime in modern Kubernetes versions without an additional adapter such as cri-dockerd.

### Container Runtime Responsibilities

- Pull container images.
- Create containers.
- Start and stop containers.
- Manage container lifecycle.
- Provide container execution functionality.

### Runtime Workflow

```text
          Kubelet
             |
             v
       CRI Interface
             |
             v
      Container Runtime
             |
       +-----+-----+
       |           |
       v           v
    Pull Image   Create Container
       |           |
       +-----+-----+
             |
             v
        Running Pod
```

---

# 📦 5. Kubernetes Request Flow

Let's understand what happens internally when an administrator creates an application Deployment.

### Example Command

```bash
kubectl create deployment nginx --image=nginx --replicas=3
```

### Step-by-Step Workflow

**Step 1: kubectl**

The administrator executes a command using kubectl.

**Step 2: API Server**

kubectl sends an API request to the API Server.

**Step 3: Authentication and Authorization**

The API Server authenticates the identity and checks whether the requested operation is authorized.

**Step 4: Admission Control**

Admission controllers validate or modify the request according to configured policies.

**Step 5: etcd**

The Deployment object is persisted in etcd.

**Step 6: Deployment Controller**

The Deployment Controller creates a ReplicaSet.

**Step 7: ReplicaSet Controller**

The ReplicaSet Controller creates three Pods.

**Step 8: Scheduler**

The Scheduler selects suitable Worker Nodes for the unscheduled Pods.

**Step 9: Kubelet**

The Kubelet on each selected node observes the assigned Pod and instructs the container runtime to create its containers.

**Step 10: Container Runtime**

The runtime pulls the image if necessary and starts the containers.

**Step 11: Status Reporting**

The Kubelet reports Pod and container status to the API Server.

### Complete Workflow Diagram

```text
             Administrator
                   |
                   v
                kubectl
                   |
                   v
              API Server
                   |
        Authentication / Authorization
                   |
                   v
            Admission Control
                   |
                   v
                 etcd
                   |
                   v
         Deployment Controller
                   |
                   v
             ReplicaSet
                   |
                   v
             Create Pods
                   |
                   v
              Scheduler
                   |
          Select Worker Nodes
                   |
          +--------+--------+
          |                 |
          v                 v
       Node-1             Node-2
          |                 |
       Kubelet            Kubelet
          |                 |
          v                 v
    Container Runtime  Container Runtime
          |                 |
          v                 v
        Pod-1             Pod-2
          |                 |
          +--------+--------+
                   |
                   v
             Pod Status
                   |
                   v
               API Server
```

---

# 🔄 6. Kubernetes Desired State vs Actual State

Kubernetes follows a declarative approach.

You define what the cluster should look like, and Kubernetes continuously works to achieve that state.

### Example

You want three Nginx replicas.

```yaml
spec:
  replicas: 3
```

Kubernetes maintains three replicas as the desired state.

| Scenario | Desired State | Actual State | Action |
|---|---:|---:|---|
| Normal | 3 | 3 | No correction needed |
| Pod deleted | 3 | 2 | Create replacement |
| Pod crashes | 3 | 2 | Reconcile workload |
| Scale to 5 | 5 | 3 | Create two more Pods |

### Reconciliation Loop

```text
       Desired State
             |
             v
       Actual State
             |
             v
       Compare States
             |
       +-----+-----+
       |           |
       v           v
      Match      Mismatch
       |           |
       v           v
    No Action   Take Action
                    |
                    v
              Desired State
```

---

# 🛡️ 7. High Availability in Kubernetes Architecture

High Availability (HA) means designing the cluster to minimize downtime and eliminate single points of failure.

### Control Plane High Availability

Production Kubernetes clusters commonly use multiple Control Plane instances.

Typical architecture:

- Multiple API Server instances.
- Multiple Scheduler instances with leader election.
- Multiple Controller Manager instances with leader election.
- Highly available etcd cluster.

### Example Architecture

```text
                Load Balancer
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
       Master-1    Master-2    Master-3
          |           |           |
          +-----------+-----------+
                      |
                   etcd
                 Cluster
                      |
          +-----------+-----------+
          |           |           |
          v           v           v
        Node-1      Node-2      Node-3
          |           |           |
          v           v           v
        Pods        Pods        Pods
```

### Important HA Considerations

- Use an odd number of etcd members, commonly three or five.
- Maintain etcd quorum.
- Distribute Control Plane nodes across failure domains where possible.
- Configure reliable API Server access.
- Use multiple Worker Nodes.
- Distribute application replicas across nodes and zones.
- Configure Pod disruption budgets.
- Maintain regular etcd backups.

**Note:** A highly available Control Plane does not automatically make applications highly available. Workload replicas, storage, networking, and failure-domain distribution must also be designed appropriately.

---

# ☁️ 8. Kubernetes Architecture in Azure AKS

Azure Kubernetes Service (AKS) provides a managed Kubernetes environment.

Microsoft manages the Kubernetes Control Plane infrastructure, while customers manage their application workloads and configure their Worker Node infrastructure.

### AKS Architecture

```text
                 Azure Cloud
                      |
                      v
             Azure Kubernetes Service
                      |
          +-----------+-----------+
          |                       |
          v                       v
     Managed Control Plane     Node Pools
          |                       |
     +----+-----+            +----+-----+
     |    |     |            |          |
     v    v     v            v          v
   API  etcd Scheduler     Worker-1   Worker-2
 Server                    |          |
     |                     v          v
     |                    Pods       Pods
     |
     +--------------------------------+
                      |
                      v
              Azure Integrations
                      |
       +--------------+---------------+
       |              |               |
       v              v               v
      ACR        Azure Networking   Azure Monitor
```

### Important AKS Components

| Component | Purpose |
|---|---|
| AKS Control Plane | Managed Kubernetes control-plane infrastructure. |
| Node Pool | Group of Worker Nodes with similar configuration. |
| Azure CNI | Provides Kubernetes Pod networking integration. |
| Azure CNI Overlay | Provides an overlay Pod networking model. |
| ACR | Stores container images. |
| Azure Load Balancer | Provides load balancing. |
| Azure Disk | Provides persistent block storage. |
| Azure Files | Provides shared file storage. |
| Azure Monitor | Provides monitoring and observability. |
| Microsoft Entra ID | Provides identity integration. |

### Important AKS Architecture Concepts

- System Node Pools.
- User Node Pools.
- Private AKS.
- Network-Isolated AKS.
- Azure CNI Overlay.
- Azure CNI Node Subnet.
- Managed Identity.
- Workload Identity.
- Application Gateway.
- Gateway API.

---

# 🔍 9. Important Kubernetes Architecture Commands

Use these commands to understand your cluster architecture.

### Cluster Information

```bash
kubectl cluster-info

kubectl get nodes -o wide

kubectl get namespaces
```

### Control Plane Information

```bash
kubectl get pods -n kube-system

kubectl get componentstatuses
```

Note: `kubectl get componentstatuses` is deprecated and unavailable in modern Kubernetes clusters. Use component Pods, logs, and monitoring instead.

### Node Information

```bash
kubectl describe nodes

kubectl get nodes -o yaml
```

### Pod Information

```bash
kubectl get pods -A -o wide

kubectl describe pod <pod-name> -n <namespace>
```

### API Server Information

```bash
kubectl cluster-info

kubectl get --raw /readyz

kubectl get --raw /livez
```

### Kubernetes API Resources

```bash
kubectl api-resources

kubectl api-versions
```

---

# 🧪 10. Hands-on Architecture Practice

Let's verify how Kubernetes architecture components work using a local KIND cluster.

### Step 1: Create a KIND Cluster

```bash
kind create cluster --name architecture-demo
```

### Step 2: Verify Nodes

```bash
kubectl get nodes -o wide
```

### Step 3: Check System Components

```bash
kubectl get pods -n kube-system -o wide
```

### Step 4: Create a Deployment

```bash
kubectl create deployment nginx \
  --image=nginx \
  --replicas=3
```

### Step 5: Check Deployment and ReplicaSet

```bash
kubectl get deployments

kubectl get replicasets
```

### Step 6: Check Pods and Node Placement

```bash
kubectl get pods -o wide
```

### Step 7: Delete One Pod

```bash
kubectl delete pod <pod-name>
```

### Step 8: Verify Self-Healing

```bash
kubectl get pods -w
```

Observe how the ReplicaSet Controller creates a replacement Pod.

### Step 9: Explore Node Details

```bash
kubectl describe node <node-name>
```

### Step 10: Cleanup

```bash
kind delete cluster --name architecture-demo
```

---

# 🎤 11. Kubernetes Architecture Interview Questions

### Basic Questions

1. Explain Kubernetes architecture.
2. What is a Control Plane?
3. What is a Worker Node?
4. What is the role of API Server?
5. What is etcd?
6. What is kube-scheduler?
7. What is kube-controller-manager?
8. What is kubelet?
9. What is kube-proxy?
10. What is a Container Runtime?

### Intermediate Questions

11. What happens when you execute `kubectl apply -f deployment.yaml`?
12. How does Kubernetes schedule a Pod?
13. How does Kubernetes perform self-healing?
14. What happens when a Worker Node goes down?
15. How does the ReplicaSet Controller work?
16. What is the reconciliation loop?
17. How does Kubernetes communicate with etcd?
18. What is the Container Runtime Interface (CRI)?
19. What is the difference between CRI, CNI, and CSI?
20. How does Kubernetes achieve High Availability?

### Advanced Questions

21. How does the Kubernetes API Server process a request?
22. Explain the Kubernetes scheduling process.
23. What happens internally when a Pod is created?
24. How does Kubernetes maintain the desired state?
25. How does etcd maintain consistency?
26. What happens if etcd becomes unavailable?
27. Explain Control Plane HA architecture.
28. How does Kubernetes handle Worker Node failure?
29. Is kube-proxy mandatory in every Kubernetes cluster?
30. Explain the architecture of Azure Kubernetes Service.

---

# 📚 12. Official Documentation

| Topic | Documentation |
|---|---|
| Kubernetes Architecture | https://kubernetes.io/docs/concepts/architecture/ |
| Control Plane | https://kubernetes.io/docs/concepts/overview/components/ |
| API Server | https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/ |
| etcd | https://etcd.io/docs/ |
| kube-scheduler | https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/ |
| kubelet | https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/ |
| Container Runtime | https://kubernetes.io/docs/setup/production-environment/container-runtimes/ |
| High Availability | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/ |
| AKS Architecture | https://learn.microsoft.com/en-us/azure/aks/concepts-clusters-workloads |

---

# 🎯 13. Key Takeaways

| Component | Remember This |
|---|---|
| API Server | Entry point for Kubernetes API requests. |
| etcd | Stores persistent cluster state. |
| Scheduler | Selects a suitable node for Pods. |
| Controller Manager | Reconciles actual state with desired state. |
| Cloud Controller Manager | Integrates with cloud infrastructure. |
| Kubelet | Manages Pods on Worker Nodes. |
| Kube-proxy | Implements Service networking rules when deployed. |
| Container Runtime | Runs containers. |

### Final Understanding

- Control Plane manages the Kubernetes cluster.
- Worker Nodes execute application workloads.
- API Server is the central communication interface.
- etcd stores persistent cluster state.
- Scheduler assigns Pods to Worker Nodes.
- Controllers maintain the desired state.
- Kubelet manages Pod execution.
- Container Runtime runs application containers.

**Kubernetes Architecture is the foundation for understanding scheduling, networking, storage, scaling, security, and production cluster management.**

---

<p align="center">
  <b>☸️ Kubernetes-AIO</b>
  <br/>
  <i>Understand the Architecture. Master the Components. Build Production-Ready Clusters.</i>
  <br/><br/>
  ⭐ If this documentation helps you, consider starring the repository!
</p>