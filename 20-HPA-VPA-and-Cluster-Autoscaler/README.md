# Kubernetes Horizontal Pod Autoscaler (HPA), Vertical Pod Autoscaler (VPA), and Cluster Autoscaler

## Table of Contents

1. [Introduction](#1-introduction)
2. [Understanding Kubernetes Autoscaling](#2-understanding-kubernetes-autoscaling)
3. [Horizontal Pod Autoscaler (HPA)](#3-horizontal-pod-autoscaler-hpa)
4. [Vertical Pod Autoscaler (VPA)](#4-vertical-pod-autoscaler-vpa)
5. [Cluster Autoscaler](#5-cluster-autoscaler)
6. [HPA vs VPA vs Cluster Autoscaler](#6-hpa-vs-vpa-vs-cluster-autoscaler)
7. [How HPA, VPA, and Cluster Autoscaler Work Together](#7-how-hpa-vpa-and-cluster-autoscaler-work-together)
8. [Prerequisites](#8-prerequisites)
9. [Hands-on Lab 1: Configure HPA](#9-hands-on-lab-1-configure-hpa)
10. [Hands-on Lab 2: Configure VPA](#10-hands-on-lab-2-configure-vpa)
11. [Hands-on Lab 3: Configure Cluster Autoscaler on AKS](#11-hands-on-lab-3-configure-cluster-autoscaler-on-aks)
12. [Monitoring Autoscaling](#12-monitoring-autoscaling)
13. [Troubleshooting](#13-troubleshooting)
14. [Best Practices](#14-best-practices)
15. [Interview Questions](#15-interview-questions)
16. [Official Documentation](#16-official-documentation)

---

## 1. Introduction

Kubernetes is designed to run applications across multiple worker nodes. In production environments, application workloads and infrastructure requirements continuously change.

For example:

- An application receives more traffic during business hours.
- A microservice suddenly experiences increased CPU consumption.
- A container requires more memory than originally configured.
- A worker node does not have enough resources to schedule additional Pods.

Manually scaling applications and infrastructure is difficult and inefficient.

Kubernetes provides three important autoscaling mechanisms:

| Autoscaler | Responsibility |
|---|---|
| HPA | Automatically increases or decreases the number of Pod replicas |
| VPA | Recommends or adjusts CPU and memory requests for containers |
| Cluster Autoscaler | Automatically adjusts the number of worker nodes |

### Real-world example

Imagine you are running an e-commerce application on AKS.

During normal traffic:

- 2 application Pods are sufficient.
- 2 worker nodes provide enough capacity.

During a major sale:

- Application traffic increases.
- CPU utilization increases.
- HPA increases the number of application Pods.
- If the existing nodes cannot accommodate the new Pods, Cluster Autoscaler can add worker nodes.

Meanwhile, VPA can analyze the application's resource requirements and recommend more appropriate CPU and memory requests.

---

## 2. Understanding Kubernetes Autoscaling

Kubernetes autoscaling operates at two primary levels:

### Workload-level scaling

Changes the resources or replica count of application workloads.

- HPA: Horizontal scaling.
- VPA: Vertical scaling.

### Infrastructure-level scaling

Changes the underlying worker-node capacity.

- Cluster Autoscaler: Node scaling.

### Autoscaling architecture

```text
                 Application Traffic
                         |
                         v
                Kubernetes Service
                         |
                         v
                  Application Pods
                         |
              +----------+----------+
              |                     |
              v                     v
             HPA                   VPA
              |                     |
       Adjust replicas       Adjust resource
              |              recommendations
              |                     |
              v                     v
          Deployment           Pod resources
              |
              v
       Kubernetes Scheduler
              |
        Available Capacity?
              |
        +-----+-----+
        |           |
       Yes          No
        |           |
        v           v
    Schedule     Pending Pods
                    |
                    v
             Cluster Autoscaler
                    |
                    v
              New Worker Nodes
```

---

## 3. Horizontal Pod Autoscaler (HPA)

### What is HPA?

Horizontal Pod Autoscaler automatically increases or decreases the number of Pod replicas based on observed metrics.

HPA commonly uses:

- CPU utilization.
- Memory utilization.
- Custom metrics.
- External metrics.

For example, if CPU utilization increases above the configured target, HPA can increase the number of application Pods.

If utilization decreases, HPA can scale down the replicas.

### How HPA works

1. HPA periodically retrieves metrics.
2. It compares current metrics against the configured target.
3. It calculates the desired number of replicas.
4. It updates the target workload's replica count.
5. The Kubernetes controller creates or removes Pods.

### HPA architecture

```text
             Metrics Server
                   |
                   v
             Resource Metrics
                   |
                   v
                  HPA
                   |
          Desired Replica Count
                   |
                   v
              Deployment
                   |
          +--------+--------+
          |        |        |
          v        v        v
         Pod-1    Pod-2    Pod-3
```

### HPA scaling formula

For a simple resource-utilization metric:

```text
Desired Replicas =
Current Replicas × (Current Metric / Target Metric)
```

Example:

- Current replicas = 2
- Current CPU utilization = 80%
- Target CPU utilization = 50%

Calculation:

```text
Desired Replicas = 2 × (80 / 50)

Desired Replicas = 3.2
```

Kubernetes rounds the result up to 4 replicas, subject to configured scaling limits and other HPA behaviour rules.

### HPA YAML example

Create a Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-hpa
  namespace: autoscaling-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-hpa
  template:
    metadata:
      labels:
        app: nginx-hpa
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "256Mi"
```

Create the HPA:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: autoscaling-demo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-hpa

  minReplicas: 2
  maxReplicas: 10

  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

### Explanation

| Parameter | Description |
|---|---|
| `scaleTargetRef` | Workload that HPA controls |
| `minReplicas` | Minimum number of replicas |
| `maxReplicas` | Maximum number of replicas |
| `metrics` | Metrics used for scaling |
| `averageUtilization` | Target average CPU utilization as a percentage of CPU requests |

**Important:** CPU utilization for this HPA metric is calculated relative to CPU requests, not CPU limits. Define CPU requests for containers so utilization can be calculated meaningfully.

### Check HPA

```bash
kubectl get hpa -n autoscaling-demo
```

Detailed information:

```bash
kubectl describe hpa nginx-hpa -n autoscaling-demo
```

Watch replica count:

```bash
kubectl get pods -n autoscaling-demo -w
```

### HPA using memory

You can also configure HPA based on memory utilization:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-memory-hpa
  namespace: autoscaling-demo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-hpa

  minReplicas: 2
  maxReplicas: 8

  metrics:
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
```

This example targets average memory utilization of 70% of the configured memory requests.

Avoid creating multiple HPAs that control the same Deployment.

### HPA using custom metrics

HPA can also scale based on application-specific metrics.

Examples:

- HTTP requests per second.
- Active user sessions.
- Queue length.
- Messages waiting in a queue.

These typically require a custom or external metrics API adapter, such as Prometheus Adapter.

Example configuration concept:

```yaml
metrics:
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
```

This example assumes the custom metric is exposed through the Kubernetes custom metrics API.

---

## 4. Vertical Pod Autoscaler (VPA)

### What is VPA?

Vertical Pod Autoscaler automatically recommends or adjusts CPU and memory resource requests for containers based on observed workload consumption.

Unlike HPA, VPA does not primarily increase the number of Pod replicas.

It focuses on the resources assigned to individual containers.

### Example

Suppose your application initially has:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
```

After monitoring application usage, VPA determines that the workload regularly needs more resources.

It might recommend:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
```

The exact recommendation depends on observed usage and VPA configuration.

### VPA components

A typical VPA installation includes three components:

| Component | Responsibility |
|---|---|
| Recommender | Analyzes historical and current resource usage and produces recommendations |
| Updater | Identifies Pods that need resource updates and can evict them for recreation |
| Admission Controller | Applies recommended resource values when Pods are created |

### VPA architecture

```text
            Application Pods
                   |
                   v
            Resource Metrics
                   |
                   v
              Recommender
                   |
                   v
          Resource Recommendations
                   |
                   v
                Updater
                   |
                   v
              Pod Eviction
                   |
                   v
          Admission Controller
                   |
                   v
             New Pod Created
                   |
                   v
          Updated Resource Values
```

### VPA update modes

VPA supports several update modes.

| Mode | Behaviour |
|---|---|
| `Off` | Generates recommendations without automatically changing Pod resources |
| `Initial` | Applies recommendations when a Pod is initially created |
| `Recreate` | Can evict and recreate Pods to apply updated resources |
| `InPlaceOrRecreate` | Attempts in-place resource updates where supported, otherwise uses recreation |

**Note:** In-place resource resizing depends on Kubernetes version, feature support, and workload/runtime constraints. VPA component versions must also support the selected mode.

### VPA YAML example

First, install the VPA components. VPA is not generally installed as part of a standard Kubernetes cluster.

For a KIND learning environment, use the official Kubernetes autoscaler VPA project:

```bash
git clone https://github.com/kubernetes/autoscaler.git

cd autoscaler/vertical-pod-autoscaler

./hack/vpa-up.sh
```

Follow the repository instructions for your Kubernetes version and environment. Verify the components:

```bash
kubectl get pods -n kube-system | grep vpa
```

Create a Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-vpa
  namespace: autoscaling-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-vpa
  template:
    metadata:
      labels:
        app: nginx-vpa
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
```

Create a VPA object:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: nginx-vpa
  namespace: autoscaling-demo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-vpa

  updatePolicy:
    updateMode: "Off"
```

Apply:

```bash
kubectl apply -f nginx-vpa.yaml
```

Check recommendations:

```bash
kubectl describe vpa nginx-vpa -n autoscaling-demo
```

You can also inspect:

```bash
kubectl get vpa nginx-vpa -n autoscaling-demo -o yaml
```

Look for:

```yaml
status:
  recommendation:
    containerRecommendations:
      - containerName: nginx
        target:
          cpu: 250m
          memory: 256Mi
```

The values above are illustrative. Actual recommendations depend on the workload's observed resource consumption.

### VPA update mode example

After validating recommendations, you can change the update mode:

```yaml
updatePolicy:
  updateMode: "Auto"
```

**Important:** `Auto` is a legacy update-mode value in some VPA versions and has historically behaved like `Recreate`. Prefer the explicitly supported mode for your installed VPA version, such as `Recreate` or `InPlaceOrRecreate`.

With `Recreate`, VPA may evict and recreate Pods to apply updated resource requests. Use appropriate PodDisruptionBudgets and sufficient replicas to manage availability.

---

## 5. Cluster Autoscaler

### What is Cluster Autoscaler?

Cluster Autoscaler automatically adjusts the number of worker nodes in a Kubernetes cluster based on Pod scheduling requirements and node utilization.

It primarily responds to unschedulable Pods and identifies nodes that can be safely removed.

### Why do we need Cluster Autoscaler?

Imagine:

- Your cluster currently has 2 worker nodes.
- HPA increases your application from 2 replicas to 10.
- Existing worker nodes do not have sufficient allocatable CPU or memory.
- Some Pods remain in Pending state.

Cluster Autoscaler can increase the node count if the configured node group or node pool allows scaling.

### How Cluster Autoscaler works

**Scale-up:**

1. A workload creates additional Pods.
2. Kubernetes scheduler attempts to place them.
3. Some Pods cannot be scheduled due to insufficient resources.
4. Cluster Autoscaler detects unschedulable Pods.
5. It evaluates eligible node groups or node pools.
6. It requests additional nodes.
7. New nodes join the cluster.
8. The scheduler places the pending Pods.

**Scale-down:**

1. Cluster Autoscaler identifies underutilized nodes.
2. It checks whether the Pods on those nodes can be moved elsewhere.
3. It considers PodDisruptionBudgets, scheduling constraints, and other safety conditions.
4. If a node can be safely removed, it drains and removes that node.

### Cluster Autoscaler architecture

```text
             HPA / Workload
                   |
                   v
              More Pods
                   |
                   v
             Kubernetes
               Scheduler
                   |
             Insufficient
               Capacity
                   |
                   v
             Pending Pods
                   |
                   v
            Cluster Autoscaler
                   |
             +-----+-----+
             |           |
             v           v
           Scale Up    Scale Down
             |           |
             v           v
        Add Nodes    Remove Nodes
             |           |
             +-----+-----+
                   |
                   v
             Worker Nodes
```

### Cluster Autoscaler configuration on AKS

AKS provides managed integration with Cluster Autoscaler through node-pool autoscaling.

You can configure it using Azure Portal or Azure CLI.

#### Option 1: Azure Portal

1. Open the Azure Portal.
2. Navigate to your AKS cluster.
3. Open **Node pools**.
4. Select the node pool you want to configure.
5. Open the scaling configuration.
6. Enable **Autoscaling**.
7. Configure:
   - Minimum node count: 2
   - Maximum node count: 5
8. Save the configuration.

The node pool can now scale within the configured boundaries when Cluster Autoscaler determines that capacity is required or can be safely removed.

#### Option 2: Azure CLI

Enable autoscaling on an existing node pool:

```bash
az aks nodepool update \
  --resource-group <RESOURCE_GROUP> \
  --cluster-name <AKS_CLUSTER_NAME> \
  --name <NODE_POOL_NAME> \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 5
```

Verify:

```bash
az aks nodepool show \
  --resource-group <RESOURCE_GROUP> \
  --cluster-name <AKS_CLUSTER_NAME> \
  --name <NODE_POOL_NAME> \
  --query "{name:name, autoscaling:enableAutoScaling, min:minCount, max:maxCount, count:count}"
```

#### Update autoscaling limits

```bash
az aks nodepool update \
  --resource-group <RESOURCE_GROUP> \
  --cluster-name <AKS_CLUSTER_NAME> \
  --name <NODE_POOL_NAME> \
  --update-cluster-autoscaler \
  --min-count 2 \
  --max-count 8
```

#### Disable autoscaling

```bash
az aks nodepool update \
  --resource-group <RESOURCE_GROUP> \
  --cluster-name <AKS_CLUSTER_NAME> \
  --name <NODE_POOL_NAME> \
  --disable-cluster-autoscaler
```

**Important AKS notes:**

- Cluster Autoscaler works with supported AKS node pools.
- Autoscaling is configured per node pool.
- The minimum and maximum counts define the permitted node range.
- Scaling is subject to Azure quotas, regional capacity, VM SKU availability, subnet IP capacity, and other infrastructure constraints.
- System node pools must maintain the required minimum capacity and cluster requirements.
- Cluster Autoscaler does not directly scale application replicas.

---

## 6. HPA vs VPA vs Cluster Autoscaler

| Feature | HPA | VPA | Cluster Autoscaler |
|---|---|---|---|
| Full name | Horizontal Pod Autoscaler | Vertical Pod Autoscaler | Cluster Autoscaler |
| Scaling level | Application | Container resources | Infrastructure |
| Primary action | Adds/removes Pod replicas | Adjusts CPU and memory requests | Adds/removes worker nodes |
| CPU metrics | Supported | Supported | Not its primary trigger |
| Memory metrics | Supported | Supported | Not its primary trigger |
| Changes replica count | Yes | No | No |
| Changes resource requests | No | Yes | No |
| Changes node count | No | No | Yes |
| Typical use | Variable application traffic | Right-sizing workloads | Insufficient cluster capacity |

### Simple way to remember

- HPA = More or fewer Pods.
- VPA = More or fewer resources per container.
- Cluster Autoscaler = More or fewer worker nodes.

---

## 7. How HPA, VPA, and Cluster Autoscaler Work Together

Consider a microservices application running on AKS.

Initial environment:

- 2 worker nodes.
- 2 application Pods.
- Each Pod requests 250m CPU and 256Mi memory.

Now application traffic increases significantly.

### Step 1: HPA scales the application

HPA observes CPU utilization above its configured target.

It increases the replica count from 2 to 8.

### Step 2: Scheduler attempts placement

Kubernetes attempts to schedule the additional Pods on existing worker nodes.

If insufficient allocatable capacity exists, some Pods remain Pending.

### Step 3: Cluster Autoscaler scales infrastructure

Cluster Autoscaler detects unschedulable Pods and requests additional nodes if the node pool can accommodate them.

### Step 4: VPA improves resource sizing

VPA analyzes historical resource usage and can recommend more suitable CPU and memory requests.

When configured with an appropriate update mode, it can apply recommendations to Pods.

### Combined architecture

```text
                 Increased Traffic
                        |
                        v
                 Application Pods
                        |
                        v
                       HPA
                        |
                 Increase Replicas
                        |
                        v
                Kubernetes Scheduler
                        |
                 Insufficient Capacity
                        |
                        v
                 Pending Pods
                        |
                        v
                Cluster Autoscaler
                        |
                  Add Worker Nodes
                        |
                        v
                 Pods Get Scheduled


                 Resource Monitoring
                        |
                        v
                       VPA
                        |
               Resource Recommendations
                        |
                        v
                 Updated Pod Resources
```

### Important design consideration

Avoid blindly using HPA and VPA together on the same CPU or memory metric.

For example, if HPA scales based on CPU utilization while VPA continuously changes CPU requests, the HPA utilization percentage can change as the denominator changes.

This can cause unexpected scaling behaviour.

A common approach is:

- HPA scales on CPU or application-specific metrics.
- VPA runs in recommendation-only mode initially.
- Resource requests are reviewed and tuned independently.
- If both controllers must be active, carefully design their metrics and update policies.

---

## 8. Prerequisites

Before starting the labs, verify your Kubernetes environment.

Check cluster connectivity:

```bash
kubectl cluster-info
```

Check worker nodes:

```bash
kubectl get nodes -o wide
```

Create a namespace:

```bash
kubectl create namespace autoscaling-demo
```

Check Metrics Server:

```bash
kubectl get deployment metrics-server -n kube-system
```

Check API resources:

```bash
kubectl api-resources | grep -E 'horizontalpodautoscalers|verticalpodautoscalers'
```

**Prerequisites by autoscaler:**

| Autoscaler | Prerequisite |
|---|---|
| HPA with CPU/memory resource metrics | Metrics Server |
| HPA with custom metrics | Custom metrics API provider |
| VPA | VPA components and CRDs |
| AKS Cluster Autoscaler | Supported AKS node pool with autoscaling enabled |

---

## 9. Hands-on Lab 1: Configure HPA

### Objective

Deploy an NGINX application and configure HPA to scale replicas based on CPU utilization.

### Step 1: Create a namespace

```bash
kubectl create namespace autoscaling-demo
```

### Step 2: Deploy an application

Save as `nginx-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-hpa
  namespace: autoscaling-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-hpa
  template:
    metadata:
      labels:
        app: nginx-hpa
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "256Mi"
```

Apply:

```bash
kubectl apply -f nginx-deployment.yaml
```

### Step 3: Create HPA

Save as `nginx-hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: autoscaling-demo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-hpa

  minReplicas: 2
  maxReplicas: 10

  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

Apply:

```bash
kubectl apply -f nginx-hpa.yaml
```

### Step 4: Verify HPA

```bash
kubectl get hpa -n autoscaling-demo
```

```bash
kubectl describe hpa nginx-hpa -n autoscaling-demo
```

### Step 5: Generate CPU load

Deploy a temporary load-generator Pod:

```bash
kubectl run load-generator \
  --namespace autoscaling-demo \
  --image=busybox:1.36 \
  --restart=Never \
  -- /bin/sh -c 'while true; do wget -q -O- http://nginx-hpa; done'
```

This generates HTTP requests against the NGINX Deployment.

For a more CPU-intensive experiment, use a dedicated load generator that consumes CPU. HTTP requests alone do not guarantee that NGINX will exceed the CPU target.

### Step 6: Watch HPA scaling

```bash
kubectl get hpa -n autoscaling-demo -w
```

In another terminal:

```bash
kubectl get pods -n autoscaling-demo -w
```

Observe the replica count.

### Step 7: Clean up

```bash
kubectl delete pod load-generator -n autoscaling-demo
```

After load decreases, HPA can scale down according to its configured behaviour and stabilization settings.

---

## 10. Hands-on Lab 2: Configure VPA

### Objective

Install VPA and inspect resource recommendations for an application.

### Step 1: Install VPA

```bash
git clone https://github.com/kubernetes/autoscaler.git

cd autoscaler/vertical-pod-autoscaler

./hack/vpa-up.sh
```

Follow the upstream installation instructions for your cluster version.

### Step 2: Deploy an application

Save as `nginx-vpa-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-vpa
  namespace: autoscaling-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-vpa
  template:
    metadata:
      labels:
        app: nginx-vpa
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
```

Apply:

```bash
kubectl apply -f nginx-vpa-deployment.yaml
```

### Step 3: Create VPA

Save as `nginx-vpa.yaml`:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: nginx-vpa
  namespace: autoscaling-demo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-vpa

  updatePolicy:
    updateMode: "Off"
```

Apply:

```bash
kubectl apply -f nginx-vpa.yaml
```

### Step 4: Inspect recommendations

```bash
kubectl get vpa -n autoscaling-demo
```

```bash
kubectl describe vpa nginx-vpa -n autoscaling-demo
```

Look for the recommendation section:

```yaml
status:
  recommendation:
    containerRecommendations:
      - containerName: nginx
        target:
          cpu: 250m
          memory: 256Mi
```

These are example values; actual recommendations are calculated from observed workload usage.

### Step 5: Understand update modes

Start with `Off` to inspect recommendations without automatically applying them.

After evaluating the recommendations, test `Recreate` in a non-production environment.

Remember that VPA may evict and recreate Pods when applying new resources in this mode.

---

## 11. Hands-on Lab 3: Configure Cluster Autoscaler on AKS

### Objective

Enable node-pool autoscaling on an AKS cluster.

### Step 1: List node pools

```bash
az aks nodepool list \
  --resource-group <RESOURCE_GROUP> \
  --cluster-name <AKS_CLUSTER_NAME> \
  -o table
```

### Step 2: Enable autoscaling

```bash
az aks nodepool update \
  --resource-group <RESOURCE_GROUP> \
  --cluster-name <AKS_CLUSTER_NAME> \
  --name <NODE_POOL_NAME> \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 5
```

### Step 3: Verify configuration

```bash
az aks nodepool show \
  --resource-group <RESOURCE_GROUP> \
  --cluster-name <AKS_CLUSTER_NAME> \
  --name <NODE_POOL_NAME> \
  -o table
```

### Step 4: Observe nodes

```bash
kubectl get nodes -w
```

### Step 5: Generate scheduling pressure

Deploy a workload with resource requests that cannot all fit on the existing nodes.

For example, create multiple replicas with relatively high CPU and memory requests.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: capacity-test
  namespace: autoscaling-demo
spec:
  replicas: 20
  selector:
    matchLabels:
      app: capacity-test
  template:
    metadata:
      labels:
        app: capacity-test
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          resources:
            requests:
              cpu: "1"
              memory: "1Gi"
```

Apply:

```bash
kubectl apply -f capacity-test.yaml
```

Observe:

```bash
kubectl get pods -n autoscaling-demo -w
kubectl get nodes -w
```

If the Pods are unschedulable due to insufficient capacity, Cluster Autoscaler may request additional nodes, provided the node pool can scale and all infrastructure constraints are satisfied.

**Cost warning:** This lab can create billable Azure infrastructure. Use a small test node pool, monitor the node count, and delete the test workload when finished.

---

## 12. Monitoring Autoscaling

### HPA monitoring

```bash
kubectl get hpa -A
```

```bash
kubectl describe hpa <HPA_NAME> -n <NAMESPACE>
```

### VPA monitoring

```bash
kubectl get vpa -A
```

```bash
kubectl describe vpa <VPA_NAME> -n <NAMESPACE>
```

### Cluster Autoscaler monitoring on AKS

Check node count:

```bash
kubectl get nodes
```

Check Pod scheduling:

```bash
kubectl get pods -A --field-selector=status.phase=Pending
```

Inspect events:

```bash
kubectl get events -A --sort-by=.lastTimestamp
```

On AKS, review the managed Cluster Autoscaler logs and diagnostics available through Azure Monitor and the configured control-plane diagnostic settings.

### Prometheus and Grafana

For production observability, useful metrics include:

| Metric | Purpose |
|---|---|
| `container_cpu_usage_seconds_total` | Container CPU consumption |
| `container_memory_working_set_bytes` | Container memory usage |
| `kube_pod_container_resource_requests` | Configured resource requests |
| `kube_pod_container_resource_limits` | Configured resource limits |
| `kube_horizontalpodautoscaler_status_current_replicas` | Current HPA replica count |
| `kube_horizontalpodautoscaler_status_desired_replicas` | Desired HPA replica count |
| `kube_node_status_allocatable` | Node allocatable capacity |

Metric availability and names depend on the exporters and monitoring stack installed.

---

## 13. Troubleshooting

### Issue 1: HPA shows `<unknown>` CPU utilization

Check:

```bash
kubectl describe hpa nginx-hpa -n autoscaling-demo
```

Possible reasons:

- Metrics Server is unavailable.
- Container CPU requests are missing.
- Metrics API is not responding.
- Pod metrics are not yet available.

Verify:

```bash
kubectl top pods -n autoscaling-demo
kubectl get apiservice v1beta1.metrics.k8s.io
```

### Issue 2: HPA is not scaling

Check:

```bash
kubectl describe hpa nginx-hpa -n autoscaling-demo
```

Investigate:

- Whether CPU usage is above the target.
- Whether the maximum replica count has been reached.
- Whether resource requests are configured.
- Whether metrics are available.
- Whether scaling policies or stabilization windows are restricting scaling.

### Issue 3: VPA recommendations are unavailable

Check:

```bash
kubectl get pods -n kube-system | grep vpa
kubectl describe vpa nginx-vpa -n autoscaling-demo
```

Investigate:

- VPA components are running.
- VPA CRDs are installed.
- The Recommender is healthy.
- Metrics are available.
- The VPA target reference is correct.

### Issue 4: Cluster Autoscaler is not adding nodes

Check:

```bash
kubectl get pods -A --field-selector=status.phase=Pending
kubectl describe pod <POD_NAME> -n <NAMESPACE>
kubectl get nodes
```

Investigate:

- Node pool maximum count.
- Azure VM quota.
- Regional VM SKU availability.
- Subnet IP capacity.
- Pod resource requests.
- Node selectors and affinity.
- Taints and tolerations.
- Storage and topology constraints.

### Issue 5: Cluster Autoscaler is not removing nodes

Possible reasons:

- Pods cannot be safely moved.
- PodDisruptionBudgets prevent eviction.
- Local storage or scheduling constraints prevent rescheduling.
- Other autoscaler safety conditions prevent node removal.

Inspect events and Cluster Autoscaler diagnostics before changing configuration.

---

## 14. Best Practices

### HPA

1. Configure CPU and memory requests correctly.
2. Choose scaling metrics based on actual application behaviour.
3. Set realistic minimum and maximum replica counts.
4. Use custom metrics for queue-driven or request-driven workloads where appropriate.
5. Configure stabilization windows to reduce scaling oscillations.
6. Ensure application readiness and startup behaviour support rapid scaling.

### VPA

1. Start with recommendation-only mode.
2. Review recommendations before applying changes.
3. Avoid unexpected Pod restarts in production.
4. Configure PodDisruptionBudgets where appropriate.
5. Avoid conflicting HPA and VPA configurations.
6. Monitor resource usage over representative traffic periods.

### Cluster Autoscaler

1. Configure appropriate minimum and maximum node counts.
2. Monitor Azure quota and subnet IP capacity.
3. Use separate node pools for different workload requirements where appropriate.
4. Ensure workloads tolerate node draining and rescheduling.
5. Configure PodDisruptionBudgets carefully.
6. Monitor scaling events and infrastructure costs.
7. Use realistic Pod resource requests to help the scheduler and Cluster Autoscaler make correct decisions.

---

## 15. Interview Questions

### Basic Questions

1. What is Kubernetes autoscaling?
2. What is the difference between HPA and VPA?
3. What is Cluster Autoscaler?
4. How does HPA calculate the desired replica count?
5. What is Metrics Server?
6. Can HPA scale based on memory?
7. What are custom metrics in HPA?
8. What are the main components of VPA?
9. What are the different VPA update modes?
10. What is the purpose of Cluster Autoscaler?

### Scenario-Based Questions

**Q1. Your application suddenly receives 10 times more traffic. How would you scale it?**

Configure HPA based on suitable CPU, memory, or application-specific metrics. Ensure the cluster has sufficient capacity and configure Cluster Autoscaler to add nodes when Pods cannot be scheduled.

**Q2. HPA increases replicas, but Pods remain Pending. What is the problem?**

The existing nodes may not have enough allocatable CPU or memory. Check Pod events and node capacity. Cluster Autoscaler may add nodes if the node pool has scaling capacity and the Pods are otherwise schedulable.

**Q3. What happens if HPA and VPA both manage CPU resources?**

VPA may change CPU requests, which affects the utilization percentage used by HPA. This can create unexpected scaling behaviour. Design their metrics and policies carefully.

**Q4. What is the difference between scaling up and scaling out?**

- Scaling up: Increasing resources assigned to an existing application instance.
- Scaling out: Increasing the number of application instances.

VPA supports vertical resource adjustment; HPA supports horizontal replica scaling.

**Q5. Can Cluster Autoscaler create a new Pod?**

No. It adjusts the number of worker nodes. Kubernetes controllers such as Deployment and HPA manage Pod creation.

**Q6. Can HPA work without Metrics Server?**

It cannot obtain standard CPU and memory resource metrics without an appropriate resource metrics API provider. Custom and external metrics require their respective metrics APIs.

**Q7. Why might Cluster Autoscaler fail to scale up even when Pods are Pending?**

The Pods might be unschedulable for reasons that adding nodes cannot resolve, such as incompatible node selectors, taints, affinity constraints, storage topology restrictions, or exhausted node-pool and infrastructure limits.

**Q8. How do you prevent frequent scaling up and down?**

Use appropriate HPA stabilization windows, scaling policies, sensible thresholds, and resource metrics that reflect actual workload demand.

**Q9. Does VPA always restart Pods?**

No. In recommendation-only mode, it does not automatically change Pod resources. Other modes may apply changes through Pod recreation or supported in-place resizing.

**Q10. How would you implement autoscaling in AKS for a production microservices application?**

- Configure HPA for application-level replica scaling.
- Use VPA recommendations to right-size CPU and memory.
- Enable Cluster Autoscaler on appropriate node pools.
- Configure readiness and liveness probes.
- Configure PodDisruptionBudgets.
- Monitor workload and infrastructure metrics using Azure Monitor, Prometheus, and Grafana.
- Validate scaling behaviour under realistic load.

---

## 16. Official Documentation

### Kubernetes

- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA Algorithm Details](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#algorithm-details)
- [Vertical Pod Autoscaler - Kubernetes Autoscaler Project](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

### Azure AKS

- [AKS Cluster Autoscaler](https://learn.microsoft.com/azure/aks/cluster-autoscaler)
- [AKS Horizontal Pod Autoscaler](https://learn.microsoft.com/azure/aks/tutorial-kubernetes-scale)
- [AKS Best Practices for Autoscaling](https://learn.microsoft.com/azure/aks/best-practices-app-cluster-reliability)

---

## Conclusion

Kubernetes autoscaling helps maintain application performance while optimizing infrastructure utilization and cost.

Remember:

- **HPA:** Automatically adjusts the number of Pod replicas.
- **VPA:** Recommends or adjusts CPU and memory requests.
- **Cluster Autoscaler:** Automatically adjusts worker-node capacity.

A production-ready Kubernetes environment often combines workload autoscaling, infrastructure autoscaling, resource management, monitoring, and availability controls.