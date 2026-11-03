# Kubernetes Pod Disruption Budget (PDB), PriorityClass, and Preemption

## Table of Contents

1. [Introduction](#1-introduction)
2. [Understanding Kubernetes Availability](#2-understanding-kubernetes-availability)
3. [Pod Disruption Budget (PDB)](#3-pod-disruption-budget-pdb)
4. [Types of Pod Disruptions](#4-types-of-pod-disruptions)
5. [PriorityClass](#5-priorityclass)
6. [Pod Preemption](#6-pod-preemption)
7. [PDB vs PriorityClass vs Preemption](#7-pdb-vs-priorityclass-vs-preemption)
8. [How These Concepts Work Together](#8-how-these-concepts-work-together)
9. [Prerequisites](#9-prerequisites)
10. [Hands-on Lab 1: Configure PDB](#10-hands-on-lab-1-configure-pdb)
11. [Hands-on Lab 2: Configure PriorityClass](#11-hands-on-lab-2-configure-priorityclass)
12. [Hands-on Lab 3: Understand Preemption](#12-hands-on-lab-3-understand-preemption)
13. [Monitoring and Verification](#13-monitoring-and-verification)
14. [Troubleshooting](#14-troubleshooting)
15. [Best Practices](#15-best-practices)
16. [Interview Questions](#16-interview-questions)
17. [Official Documentation](#17-official-documentation)

---

## 1. Introduction

Kubernetes provides several mechanisms to maintain application availability and manage workloads during resource contention and infrastructure maintenance.

Consider a production application running with five replicas across multiple worker nodes.

What happens when:

- An administrator drains a worker node?
- A worker node requires maintenance?
- A new high-priority application needs resources?
- The cluster does not have enough CPU or memory?
- Kubernetes needs to decide which Pods should be terminated first?

Kubernetes provides three important mechanisms to address these scenarios:

| Concept | Responsibility |
|---|---|
| Pod Disruption Budget (PDB) | Controls how many replicas can voluntarily become unavailable during supported eviction operations |
| PriorityClass | Defines the relative scheduling priority of Pods |
| Preemption | Allows the scheduler to remove lower-priority Pods to make room for higher-priority Pods |

These concepts are particularly important for production Kubernetes clusters, including Azure Kubernetes Service (AKS).

---

## 2. Understanding Kubernetes Availability

Before understanding PDB, PriorityClass, and Preemption, it is important to understand Pod availability.

Consider a Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
spec:
  replicas: 5
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

Kubernetes maintains five desired replicas.

However, if two Pods become unavailable during maintenance, only three replicas remain available.

This can affect application availability and performance.

Kubernetes uses different mechanisms to manage this situation:

- Deployments maintain the desired replica count.
- PodDisruptionBudgets limit certain voluntary disruptions.
- PriorityClass assigns workload importance.
- Preemption helps schedule higher-priority workloads when resources are insufficient.

---

## 3. Pod Disruption Budget (PDB)

### What is PDB?

A Pod Disruption Budget defines the minimum number of Pods that must remain available, or the maximum number that can be unavailable, during supported voluntary disruption operations.

PDB helps protect application availability during activities such as:

- Worker node maintenance.
- Node draining.
- Cluster upgrades.
- Voluntary Pod eviction through the Kubernetes Eviction API.

### Why do we need PDB?

Imagine an application running with five replicas.

During node maintenance, an administrator wants to drain one worker node.

Without a PDB, Kubernetes may evict multiple application Pods during the operation, depending on where they are running.

With a PDB, you can control the permitted level of voluntary disruption.

### PDB architecture

```text
                 Kubernetes Cluster
                         |
                  Application Deployment
                         |
                  5 Running Replicas
                         |
                         v
                Pod Disruption Budget
                         |
                  Minimum Available: 4
                         |
                         v
                  Node Maintenance
                         |
                  Eviction Request
                         |
                  +------+------+
                  |             |
              Allowed        Blocked
                  |             |
                  v             v
             Evict Pod     Protect Remaining
                            Availability
```

### PDB configuration

There are two main ways to configure a PDB:

1. `minAvailable`
2. `maxUnavailable`

### 3.1 minAvailable

Specifies the minimum number or percentage of matching Pods that must remain healthy and available during voluntary disruptions.

Example:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
  namespace: production
spec:
  minAvailable: 4
  selector:
    matchLabels:
      app: nginx
```

Explanation:

- Application has five matching Pods.
- At least four must remain available.
- One Pod can be voluntarily disrupted at a time, assuming the PDB's other conditions are satisfied.

### 3.2 maxUnavailable

Specifies the maximum number or percentage of matching Pods that can be unavailable due to voluntary disruptions.

Example:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
  namespace: production
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: nginx
```

Explanation:

- Application has five matching Pods.
- At most one can be unavailable due to disruptions covered by the PDB.

### minAvailable vs maxUnavailable

| Feature | minAvailable | maxUnavailable |
|---|---|---|
| Purpose | Defines minimum healthy Pods | Defines maximum unavailable Pods |
| Example | 4 | 1 |
| With 5 replicas | At least 4 available | At most 1 unavailable |
| Percentage supported | Yes | Yes |

**Important:** Configure either `minAvailable` or `maxUnavailable`, not both in the same PDB.

### 3.3 Percentage-based PDB

You can also configure PDB using percentages.

Example:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
  namespace: production
spec:
  minAvailable: "80%"
  selector:
    matchLabels:
      app: nginx
```

For five matching Pods, 80% means at least four Pods must remain available.

Kubernetes rounds percentage-based `minAvailable` values up.

For percentage-based `maxUnavailable`, Kubernetes rounds the calculated number up as well.

### 3.4 PDB status

Check PDB:

```bash
kubectl get pdb -n production
```

Detailed information:

```bash
kubectl describe pdb nginx-pdb -n production
```

Example output:

```text
Name:             nginx-pdb
Namespace:        production
Min available:   4
Allowed disruptions: 1
Current:          5
Desired:          4
Total:            5
```

The `Allowed disruptions` field indicates how many additional voluntary disruptions are currently permitted by the budget.

---

## 4. Types of Pod Disruptions

Kubernetes distinguishes between voluntary and involuntary disruptions.

### 4.1 Voluntary disruptions

These are disruptions initiated through planned operations or administrative actions.

Examples:

- `kubectl drain`.
- Node maintenance.
- Cluster upgrades.
- Eviction API requests.
- Deleting a workload through an administrative process.

PDB can protect against supported voluntary eviction operations.

### 4.2 Involuntary disruptions

These occur without a planned voluntary eviction request.

Examples:

- Node hardware failure.
- Node power failure.
- Kernel crash.
- Out-of-memory termination.
- Unexpected infrastructure failure.

PDB does not prevent involuntary disruptions.

### Comparison

| Feature | Voluntary | Involuntary |
|---|---|---|
| Planned operation | Usually | No |
| Example | Node drain | Node failure |
| PDB protection | Applies to supported eviction operations | Does not prevent the disruption |
| Administrative control | Higher | Limited |

**Important:** PDB is not a complete high-availability solution. Use multiple replicas, readiness probes, topology spread constraints, and appropriate infrastructure redundancy as well.

---

## 5. PriorityClass

### What is PriorityClass?

PriorityClass is a cluster-scoped Kubernetes resource used to assign scheduling priority to Pods.

It helps Kubernetes determine which workloads should receive scheduling preference when resources are limited.

A higher numerical priority value represents a higher priority.

### Why do we need PriorityClass?

Imagine a Kubernetes cluster running:

- Payment service.
- Monitoring application.
- Development application.
- Background batch processing.

If the cluster has insufficient resources, the payment service may need to receive scheduling preference over less critical workloads.

PriorityClass allows administrators to define these workload priorities.

### PriorityClass architecture

```text
                Kubernetes Cluster
                        |
                  Pending Pods
                        |
                        v
                 Kubernetes Scheduler
                        |
                 Compare Priorities
                        |
             +----------+----------+
             |                     |
             v                     v
        High Priority         Low Priority
             |                     |
             v                     v
       Scheduling First      Wait for Capacity
```

### PriorityClass YAML

Create a high-priority class:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 100000
globalDefault: false
description: "Priority class for critical production applications."
```

Create a medium-priority class:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority
value: 50000
globalDefault: false
description: "Priority class for standard applications."
```

Create a low-priority class:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 10000
globalDefault: false
description: "Priority class for non-critical applications."
```

Apply:

```bash
kubectl apply -f priority-classes.yaml
```

Verify:

```bash
kubectl get priorityclass
```

### PriorityClass parameters

| Parameter | Description |
|---|---|
| `value` | Numerical scheduling priority |
| `globalDefault` | Determines whether the class is the default for Pods without an explicit priority class |
| `description` | Explains the purpose of the priority class |
| `preemptionPolicy` | Controls whether Pods using this class may preempt lower-priority Pods |

### Important points

1. PriorityClass is cluster-scoped.
2. Higher numerical values represent higher priority.
3. Pods reference a PriorityClass through `priorityClassName`.
4. Priority affects scheduling order.
5. PriorityClass does not guarantee that a Pod will immediately run.
6. PriorityClass can also influence eviction ordering under node-pressure conditions.

Kubernetes provides built-in priority classes such as:

- `system-cluster-critical`
- `system-node-critical`

Avoid using these system priority classes for ordinary application workloads.

---

## 6. Pod Preemption

### What is Preemption?

Preemption is a scheduling mechanism that allows Kubernetes to remove lower-priority Pods to make room for a higher-priority Pod when the scheduler cannot otherwise find a suitable node.

Preemption is associated with Pod Priority.

### Why do we need Preemption?

Imagine a worker node with:

- 4 CPU cores.
- 8 GiB memory.

The node is already running lower-priority workloads.

A new high-priority Pod requires:

- 2 CPU cores.
- 2 GiB memory.

If the node has insufficient available resources, the scheduler may identify lower-priority Pods that can be removed to accommodate the new Pod.

### Preemption architecture

```text
                 Worker Node
                      |
             Available Resources
                      |
                 Not Enough
                      |
                      v
              High Priority Pod
                      |
                      v
              Kubernetes Scheduler
                      |
              Evaluate Preemption
                      |
                      v
             Identify Lower-Priority
                    Pods
                      |
                      v
              Remove Victim Pods
                      |
                      v
              Schedule New Pod
```

### How preemption works

1. A high-priority Pod enters Pending state.
2. The scheduler attempts normal scheduling.
3. If no suitable node is available, the scheduler evaluates preemption.
4. It identifies nodes where removing lower-priority Pods could make the new Pod schedulable.
5. It selects suitable victim Pods.
6. The scheduler initiates preemption.
7. Victim Pods are terminated, subject to their graceful termination periods.
8. The higher-priority Pod can be scheduled once sufficient resources become available.

### Preemption YAML example

First, create a PriorityClass:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: critical-priority
value: 100000
globalDefault: false
description: "Critical application workloads."
```

Create a lower-priority class:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: normal-priority
value: 10000
globalDefault: false
description: "Normal application workloads."
```

Create a low-priority Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: low-priority-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: low-priority-app
  template:
    metadata:
      labels:
        app: low-priority-app
    spec:
      priorityClassName: normal-priority
      containers:
        - name: nginx
          image: nginx:latest
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
```

Create a high-priority Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: high-priority-pod
spec:
  priorityClassName: critical-priority
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "2"
          memory: "2Gi"
```

The high-priority Pod may preempt lower-priority Pods if the scheduler determines that doing so can make the Pod schedulable.

**Important:** This example does not guarantee preemption. It depends on actual node capacity, Pod placement, scheduling constraints, and scheduler decisions.

### Preemption policy

PriorityClass supports two preemption policies:

#### 1. PreemptLowerPriority

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: critical-priority
value: 100000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
```

This is the default behaviour.

Pods using this class may preempt lower-priority Pods when necessary.

#### 2. Never

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: no-preemption-priority
value: 100000
globalDefault: false
preemptionPolicy: Never
```

Pods using this class cannot preempt lower-priority Pods.

However, they retain their scheduling priority and are considered ahead of lower-priority Pods in scheduling queues.

They may remain Pending until suitable resources become available.

---

## 7. PDB vs PriorityClass vs Preemption

| Feature | PDB | PriorityClass | Preemption |
|---|---|---|---|
| Main purpose | Protect availability during supported voluntary disruptions | Assign workload priority | Make room for higher-priority workloads |
| Controls scheduling priority | No | Yes | Uses Pod priority |
| Controls Pod eviction | Limits supported voluntary evictions | Influences eviction ordering | Removes lower-priority Pods |
| Resource management | No direct resource allocation | No direct resource allocation | Frees resources by removing Pods |
| Scope | Namespaced | Cluster-scoped | Scheduler operation |
| Typical use | Node maintenance | Critical workloads | Resource contention |

### Simple way to remember

- **PDB:** How many Pods can be voluntarily disrupted?
- **PriorityClass:** Which workload is more important?
- **Preemption:** Can a higher-priority workload make room by removing lower-priority workloads?

---

## 8. How These Concepts Work Together

Consider a production payment application running with five replicas.

The cluster also runs monitoring and development workloads.

### Scenario

- Payment application: High priority.
- Monitoring application: Medium priority.
- Development application: Low priority.
- Payment application PDB: Minimum four available replicas.

### Step 1: Configure PriorityClass

Assign a higher priority to the payment application.

### Step 2: Configure PDB

Ensure at least four payment Pods remain available during supported voluntary disruptions.

### Step 3: Resource contention occurs

A new payment Pod cannot be scheduled because worker nodes lack sufficient resources.

### Step 4: Scheduler evaluates preemption

The scheduler may select lower-priority development Pods as victims if removing them makes the payment Pod schedulable.

### Step 5: Node maintenance

When an administrator drains a worker node, PDB controls supported voluntary eviction requests for the payment Pods.

### Combined architecture

```text
                 Production Cluster
                         |
              +----------+----------+
              |          |          |
              v          v          v
           Payment   Monitoring  Development
           Service    Service      Service
              |          |          |
              v          v          v
           High       Medium       Low
          Priority   Priority    Priority
              |
              v
             PDB
              |
      Minimum 4 Available
              |
              v
        Node Maintenance
              |
       Controlled Eviction


       Resource Contention
              |
              v
       High Priority Pod
              |
              v
       Scheduler Preemption
              |
              v
       Lower Priority Pods
          May Be Removed
```

**Important:** PDB is not a universal protection against all Pod deletion or termination paths. Scheduler preemption is also not a general replacement for Cluster Autoscaler. The scheduler may prefer a different node or wait for capacity if preemption cannot make a Pod schedulable.

---

## 9. Prerequisites

For these labs, use your KIND or AKS cluster.

Verify connectivity:

```bash
kubectl cluster-info
```

Check nodes:

```bash
kubectl get nodes -o wide
```

Create a namespace:

```bash
kubectl create namespace availability-demo
```

Check PriorityClass support:

```bash
kubectl api-resources | grep priorityclass
```

Check PDB support:

```bash
kubectl api-resources | grep poddisruptionbudgets
```

---

## 10. Hands-on Lab 1: Configure PDB

### Objective

Create an NGINX Deployment with five replicas and configure a PDB to maintain at least four available replicas during supported voluntary disruptions.

### Step 1: Create Deployment

Save as `nginx-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
  namespace: availability-demo
spec:
  replicas: 5
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
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
```

Apply:

```bash
kubectl apply -f nginx-deployment.yaml
```

Verify:

```bash
kubectl get pods -n availability-demo -o wide
```

### Step 2: Create PDB

Save as `nginx-pdb.yaml`:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
  namespace: availability-demo
spec:
  minAvailable: 4
  selector:
    matchLabels:
      app: nginx
```

Apply:

```bash
kubectl apply -f nginx-pdb.yaml
```

### Step 3: Verify PDB

```bash
kubectl get pdb -n availability-demo
```

```bash
kubectl describe pdb nginx-pdb -n availability-demo
```

Expected initial state:

```text
Min available:       4
Current:             5
Desired:             4
Allowed disruptions: 1
```

### Step 4: Test node drain

First, identify a worker node:

```bash
kubectl get nodes
```

Drain the selected node:

```bash
kubectl drain <NODE_NAME> --ignore-daemonsets
```

Kubernetes will attempt to evict Pods using the Eviction API.

The PDB limits how many matching Pods can be voluntarily disrupted at once.

If the drain operation cannot proceed without violating the PDB, it can remain blocked or report that the disruption is not allowed.

### Step 5: Restore the node

```bash
kubectl uncordon <NODE_NAME>
```

**Important:** Perform this lab on a disposable test cluster. A single-node KIND cluster or an AKS system node should not be used casually for drain experiments.

---

## 11. Hands-on Lab 2: Configure PriorityClass

### Objective

Create different PriorityClasses and assign them to application Pods.

### Step 1: Create PriorityClass

Save as `priority-class.yaml`:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 100000
globalDefault: false
description: "Priority for critical applications."
```

Apply:

```bash
kubectl apply -f priority-class.yaml
```

### Step 2: Create Deployment

Save as `high-priority-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: availability-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      priorityClassName: high-priority
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
kubectl apply -f high-priority-deployment.yaml
```

### Step 3: Verify Pod priority

```bash
kubectl get pods -n availability-demo
```

Inspect a Pod:

```bash
kubectl describe pod <POD_NAME> -n availability-demo
```

Look for:

```text
Priority Class Name:  high-priority
Priority:             100000
```

You can also inspect the priority directly:

```bash
kubectl get pod <POD_NAME> \
  -n availability-demo \
  -o jsonpath='{.spec.priority}'
```

---

## 12. Hands-on Lab 3: Understand Preemption

### Objective

Understand how Kubernetes can schedule a higher-priority Pod by preempting lower-priority Pods.

### Step 1: Create low-priority PriorityClass

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 1000
globalDefault: false
```

### Step 2: Create high-priority PriorityClass

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: critical-priority
value: 100000
globalDefault: false
```

Apply both:

```bash
kubectl apply -f priority-classes.yaml
```

### Step 3: Create low-priority workload

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: low-priority-app
  namespace: availability-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: low-priority-app
  template:
    metadata:
      labels:
        app: low-priority-app
    spec:
      priorityClassName: low-priority
      containers:
        - name: nginx
          image: nginx:latest
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
```

Apply:

```bash
kubectl apply -f low-priority-app.yaml
```

### Step 4: Create high-priority Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-pod
  namespace: availability-demo
spec:
  priorityClassName: critical-priority
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "2"
          memory: "2Gi"
```

Apply:

```bash
kubectl apply -f critical-pod.yaml
```

### Step 5: Observe scheduling

```bash
kubectl get pods -n availability-demo -o wide
```

Inspect the high-priority Pod:

```bash
kubectl describe pod critical-pod -n availability-demo
```

Check events:

```bash
kubectl get events -n availability-demo --sort-by=.lastTimestamp
```

Look for scheduling or preemption events.

**Important:** This lab demonstrates the configuration, not a guaranteed preemption result. On a cluster with sufficient free resources, the critical Pod may schedule without preemption. On a small cluster, it may remain Pending if no suitable victim selection can make it schedulable.

To reliably test preemption, use a dedicated multi-node test cluster with carefully controlled allocatable capacity and resource requests.

---

## 13. Monitoring and Verification

### Check PDB

```bash
kubectl get pdb -A
```

```bash
kubectl describe pdb <PDB_NAME> -n <NAMESPACE>
```

### Check PriorityClass

```bash
kubectl get priorityclass
```

### Check Pod priority

```bash
kubectl get pods -n availability-demo \
  -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,CLASS:.spec.priorityClassName
```

### Check Pending Pods

```bash
kubectl get pods -A --field-selector=status.phase=Pending
```

### Check scheduling events

```bash
kubectl get events -A --sort-by=.lastTimestamp
```

### Check node status

```bash
kubectl get nodes -o wide
```

For production monitoring, track:

- PDB allowed disruptions.
- PDB disruptions allowed versus blocked.
- Pending Pods.
- Failed scheduling events.
- Node readiness.
- Pod restart counts.
- Application availability.

Prometheus and Grafana can be used to build dashboards around these metrics.

---

## 14. Troubleshooting

### Issue 1: Node drain is blocked

Possible message:

```text
Cannot evict pod as it would violate the pod's disruption budget.
```

**Reason:**

The eviction would violate the configured PDB.

**Solution:**

```bash
kubectl describe pdb <PDB_NAME> -n <NAMESPACE>
```

Check:

- Current available replicas.
- Desired healthy replicas.
- Allowed disruptions.
- Whether replacement Pods are ready.

Do not immediately bypass the PDB. First evaluate application availability and maintenance risk.

### Issue 2: PDB shows zero allowed disruptions

Possible reasons:

- Too few healthy replicas.
- Pods are not Ready.
- `minAvailable` is too high.
- `maxUnavailable` is too low.
- A previous disruption is still being accounted for.

**Solution:**

```bash
kubectl get pods -n <NAMESPACE>
kubectl describe pdb <PDB_NAME> -n <NAMESPACE>
```

Ensure the workload has sufficient healthy replicas.

### Issue 3: High-priority Pod is Pending

Check:

```bash
kubectl describe pod <POD_NAME> -n <NAMESPACE>
```

Possible reasons:

- Insufficient CPU or memory.
- Node affinity or selector mismatch.
- Untolerated node taints.
- Storage topology constraints.
- No suitable lower-priority victims for preemption.
- Preemption is disabled for the Pod's PriorityClass.

**Solution:**

Review Pod resource requests, node capacity, PriorityClass, and scheduling constraints.

### Issue 4: Preemption is not happening

Possible reasons:

- Sufficient resources are already available.
- The high-priority Pod cannot fit even after removing lower-priority Pods.
- No eligible lower-priority Pods can be removed.
- PodDisruptionBudget constraints affect victim selection.
- The Pod uses `preemptionPolicy: Never`.

Inspect:

```bash
kubectl describe pod <POD_NAME> -n <NAMESPACE>
kubectl get priorityclass
kubectl get events -n <NAMESPACE> --sort-by=.lastTimestamp
```

---

## 15. Best Practices

### Pod Disruption Budget

1. Configure PDB for critical multi-replica applications.
2. Choose `minAvailable` or `maxUnavailable` based on availability requirements.
3. Maintain sufficient replicas to support node maintenance.
4. Combine PDB with topology spread constraints and Pod anti-affinity where appropriate.
5. Avoid setting overly restrictive budgets that prevent necessary maintenance.
6. Remember that PDB does not protect against involuntary failures.
7. Ensure replacement Pods can become Ready before relying on their availability.

### PriorityClass

1. Define clear workload priority levels.
2. Reserve the highest priorities for genuinely critical workloads.
3. Avoid assigning excessive priority to every application.
4. Use RBAC and admission policies to control who can assign sensitive priority classes.
5. Document the business purpose of each PriorityClass.
6. Avoid using system-critical PriorityClasses for ordinary workloads.

### Preemption

1. Use preemption carefully in multi-tenant clusters.
2. Ensure high-priority workloads have realistic resource requests.
3. Monitor lower-priority workloads that may be repeatedly preempted.
4. Consider `preemptionPolicy: Never` for workloads that should have scheduling preference without evicting other workloads.
5. Use Cluster Autoscaler as a complementary capacity-management mechanism.
6. Validate PodDisruptionBudget behaviour before production rollout.

---

## 16. Interview Questions

### Basic Questions

1. What is a Pod Disruption Budget?
2. What is the difference between `minAvailable` and `maxUnavailable`?
3. What are voluntary and involuntary disruptions?
4. Does PDB protect Pods from node failure?
5. What is PriorityClass?
6. Is PriorityClass namespaced or cluster-scoped?
7. What happens when a Pod has a higher priority?
8. What is Pod preemption?
9. What is the difference between scheduling priority and preemption?
10. What is the default preemption policy?

### Scenario-Based Questions

**Q1. You have a Deployment with five replicas and a PDB with `minAvailable: 4`. How many Pods can be voluntarily disrupted at once?**

One, assuming all five replicas are healthy and the disruption is handled through a supported eviction operation.

**Q2. Your AKS node drain is blocked because of a PDB. What would you do?**

Inspect the PDB status, application health, and replica count. Ensure replacement replicas are available before continuing maintenance. Avoid bypassing the PDB without assessing availability impact.

**Q3. Can PDB prevent a Pod from being terminated when its node crashes?**

No. PDB does not prevent involuntary disruptions such as node failures.

**Q4. You have a high-priority Pod in Pending state. What can Kubernetes do?**

The scheduler first attempts normal scheduling. If no node is suitable, it may evaluate preemption and remove lower-priority Pods if doing so makes the Pod schedulable.

**Q5. Does a higher-priority Pod always preempt a lower-priority Pod?**

No. Preemption occurs only when it can help the Pod become schedulable and the relevant scheduling conditions are satisfied.

**Q6. What is the difference between PDB and PriorityClass?**

PDB controls the permitted level of supported voluntary disruptions. PriorityClass defines workload scheduling priority and can influence eviction ordering.

**Q7. Can two Pods with different PriorityClasses run on the same node?**

Yes. PriorityClass does not reserve an entire node for a particular workload. Multiple workloads with different priorities can share a node.

**Q8. What happens if `preemptionPolicy` is set to `Never`?**

The Pod retains its scheduling priority but cannot preempt lower-priority Pods. It may wait until resources become available.

**Q9. How do PDB and Cluster Autoscaler work together?**

Cluster Autoscaler may need to drain nodes during scale-down. PDB can prevent eviction when removing Pods would violate the budget, potentially delaying node removal.

**Q10. How would you design high availability for a payment application on AKS?**

Use multiple replicas, readiness and liveness probes, PDB, topology spread constraints across availability zones, appropriate PriorityClass, resource requests and limits, and Cluster Autoscaler. Monitor application availability and validate node maintenance procedures.

---

## 17. Official Documentation

### Kubernetes

- [Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
- [Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [Safely Drain a Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [Pod Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)

### Azure AKS

- [AKS Best Practices for Cluster Reliability](https://learn.microsoft.com/azure/aks/best-practices-app-cluster-reliability)
- [AKS Cluster Autoscaler](https://learn.microsoft.com/azure/aks/cluster-autoscaler)
- [AKS Node Pools](https://learn.microsoft.com/azure/aks/create-node-pools)

---

## Conclusion

PDB, PriorityClass, and Preemption are important Kubernetes mechanisms for maintaining workload availability and managing scheduling under resource contention.

Remember:

- **PDB:** Controls supported voluntary disruption levels.
- **PriorityClass:** Defines workload scheduling priority.
- **Preemption:** Allows higher-priority workloads to make room by removing lower-priority workloads when necessary.

Together with multiple replicas, topology spread constraints, resource management, and Cluster Autoscaler, these features help build resilient and production-ready Kubernetes environments.
