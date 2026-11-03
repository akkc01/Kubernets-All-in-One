# Kubernetes Topology Spread Constraints

## 1. Introduction

Kubernetes Topology Spread Constraints help distribute application Pods evenly across different topology domains within a cluster.

They improve application availability, fault tolerance, and workload distribution.

For example, imagine you have an application with six replicas running in an AKS cluster.

Your cluster has three availability zones:

- Zone 1
- Zone 2
- Zone 3

Without topology spread constraints, Kubernetes might schedule all six Pods in a single zone.

If that availability zone fails, your application could become unavailable.

With Topology Spread Constraints, you can instruct Kubernetes to distribute replicas across different nodes or availability zones.

### Why Do We Need Topology Spread Constraints?

- Improve application availability.
- Distribute replicas across worker nodes.
- Distribute workloads across availability zones.
- Reduce the impact of node failures.
- Reduce the impact of availability-zone failures.
- Improve workload resilience.

## 2. What Is a Topology Domain?

A topology domain is a group of nodes that share a particular topology label.

Kubernetes uses node labels to identify topology domains.

Common topology labels:

| Topology Key | Description |
|---|---|
| `kubernetes.io/hostname` | Individual worker node |
| `topology.kubernetes.io/zone` | Availability zone |
| `topology.kubernetes.io/region` | Cloud region |

Example:

| Node | Zone | Hostname |
|---|---|---|
| worker-1 | zone-1 | worker-1 |
| worker-2 | zone-1 | worker-2 |
| worker-3 | zone-2 | worker-3 |
| worker-4 | zone-2 | worker-4 |
| worker-5 | zone-3 | worker-5 |
| worker-6 | zone-3 | worker-6 |

If you use:

```yaml
topologyKey: topology.kubernetes.io/zone
```

Kubernetes distributes Pods across availability zones.

If you use:

```yaml
topologyKey: kubernetes.io/hostname
```

Kubernetes distributes Pods across individual worker nodes.

## 3. Important Topology Spread Constraint Parameters

Topology Spread Constraints use several important parameters.

### 3.1 maxSkew

`maxSkew` defines the maximum permitted difference in matching Pod counts between eligible topology domains.

Example:

```yaml
maxSkew: 1
```

This means the difference between the highest and lowest matching Pod counts across eligible domains must not exceed 1 when the constraint is satisfied.

Example distribution:

| Zone | Number of Pods |
|---|---:|
| Zone 1 | 2 |
| Zone 2 | 2 |
| Zone 3 | 1 |

The difference is:

`2 - 1 = 1`

This satisfies `maxSkew: 1`.

### 3.2 topologyKey

Defines the topology domain used for distribution.

Example:

```yaml
topologyKey: topology.kubernetes.io/zone
```

This distributes Pods across availability zones.

### 3.3 whenUnsatisfiable

Defines what Kubernetes should do when a scheduling decision cannot satisfy the spread constraint.

Two supported values:

| Value | Behavior |
|---|---|
| DoNotSchedule | Hard constraint; Pod remains Pending if the constraint cannot be satisfied |
| ScheduleAnyway | Soft constraint; scheduler still schedules the Pod, preferring better-balanced placement |

Example:

```yaml
whenUnsatisfiable: DoNotSchedule
```

### 3.4 labelSelector

Identifies the existing Pods that should be counted for distribution.

Example:

```yaml
labelSelector:
  matchLabels:
    app: nginx
```

Only Pods matching `app=nginx` are considered for this constraint.

### 3.5 minDomains

Specifies the minimum number of eligible topology domains required for the constraint.

Example:

```yaml
minDomains: 3
```

If fewer than three eligible domains exist, Kubernetes treats the global minimum as zero for calculating skew.

This can affect whether a new Pod can be scheduled with `DoNotSchedule`.

`minDomains` is supported with `whenUnsatisfiable: DoNotSchedule`.

### 3.6 nodeAffinityPolicy and nodeTaintsPolicy

These optional settings control how node affinity and taints affect the eligible topology domains.

| Parameter | Description |
|---|---|
| `nodeAffinityPolicy` | Controls whether node affinity and node selector are considered when calculating eligible domains |
| `nodeTaintsPolicy` | Controls whether node taints are considered when calculating eligible domains |

Supported values are `Honor` and `Ignore`.

Example:

```yaml
nodeAffinityPolicy: Honor
nodeTaintsPolicy: Honor
```

These settings are useful when workloads are restricted to particular node pools.

## 4. How maxSkew Works

Suppose you have three availability zones and six application replicas.

Your desired distribution is:

| Zone | Pods |
|---|---:|
| Zone 1 | 2 |
| Zone 2 | 2 |
| Zone 3 | 2 |

This is a perfectly balanced distribution.

Now consider:

| Zone | Pods |
|---|---:|
| Zone 1 | 4 |
| Zone 2 | 1 |
| Zone 3 | 1 |

The difference is:

`4 - 1 = 3`

If `maxSkew: 1`, this distribution is not balanced.

**Important:** `maxSkew` is evaluated when the scheduler makes placement decisions. It does not continuously rebalance existing Pods if the cluster topology or Pod distribution changes.

## 5. Topology Spread Constraint YAML

Example Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: nginx

      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Explanation:

- `replicas: 6`: Creates six application replicas.
- `maxSkew: 1`: Limits the difference between domain Pod counts to one.
- `topologyKey`: Uses availability zones for distribution.
- `whenUnsatisfiable: DoNotSchedule`: Prevents scheduling if the hard spread rule cannot be satisfied.
- `labelSelector`: Counts Pods labeled `app=nginx`.

**Note:** The nodes must have the specified zone labels, and enough eligible topology domains must exist for the desired distribution.

## 6. Difference Between DoNotSchedule and ScheduleAnyway

### DoNotSchedule

This is a hard scheduling constraint.

If scheduling a Pod would violate the configured spread requirement, the scheduler leaves it Pending.

Example:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: nginx
```

### ScheduleAnyway

This is a soft scheduling constraint.

The scheduler can still schedule the Pod even if the resulting distribution is not perfectly balanced.

It prefers nodes that improve the distribution.

Example:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app: nginx
```

## 7. Hands-On Lab: Topology Spread Constraints Using KIND

Let's implement topology spread constraints using a local KIND cluster.

### Prerequisites

- Docker Desktop
- KIND
- kubectl
- A multi-node KIND cluster

### Step 1: Create a Multi-Node KIND Cluster

Create `kind-topology.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
  - role: control-plane

  - role: worker

  - role: worker

  - role: worker
```

Create the cluster:

```bash
kind create cluster \
  --name topology-lab \
  --config kind-topology.yaml
```

Verify:

```bash
kubectl get nodes -o wide
```

### Step 2: Create a Namespace

```bash
kubectl create namespace topology-demo
```

Verify:

```bash
kubectl get namespaces
```

### Step 3: Check Node Labels

```bash
kubectl get nodes --show-labels
```

KIND nodes normally have hostname labels, but they do not automatically represent three real cloud availability zones.

For this lab, create three simulated zone labels on the worker nodes.

### Step 4: Add Simulated Zone Labels

List the nodes:

```bash
kubectl get nodes
```

Apply labels:

```bash
kubectl label nodes topology-lab-worker topology.kubernetes.io/zone=zone-a

kubectl label nodes topology-lab-worker2 topology.kubernetes.io/zone=zone-b

kubectl label nodes topology-lab-worker3 topology.kubernetes.io/zone=zone-c
```

Replace the node names if your cluster uses different names.

Verify:

```bash
kubectl get nodes \
  -L topology.kubernetes.io/zone
```

Expected output:

```text
NAME                       STATUS   ZONE
topology-lab-control-plane Ready    <none>
topology-lab-worker        Ready    zone-a
topology-lab-worker2       Ready    zone-b
topology-lab-worker3       Ready    zone-c
```

The zone labels are simulated for this local exercise. They do not create real availability zones.

### Step 5: Create a Deployment With Topology Spread Constraints

Create `nginx-topology.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-topology
  namespace: topology-demo
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx-topology
  template:
    metadata:
      labels:
        app: nginx-topology
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: nginx-topology

      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f nginx-topology.yaml
```

### Step 6: Verify Pod Distribution

```bash
kubectl get pods \
  -n topology-demo \
  -o wide
```

Check the zone of each node:

```bash
kubectl get nodes \
  -L topology.kubernetes.io/zone
```

To summarize Pod distribution by zone:

```bash
kubectl get pods \
  -n topology-demo \
  -o json |
jq -r '
  .items[]
  | select(.status.phase == "Running")
  | .spec.nodeName
' |
while read node; do
  kubectl get node "$node" \
    -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
  echo
done |
sort |
uniq -c
```

Expected distribution:

```text
2 zone-a
2 zone-b
2 zone-c
```

The exact placement can vary, but with three eligible zones, six replicas, and `maxSkew: 1`, the expected balanced distribution is two Pods per zone.

### Step 7: Test With ScheduleAnyway

Create another Deployment using:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-soft-spread
  namespace: topology-demo
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx-soft-spread
  template:
    metadata:
      labels:
        app: nginx-soft-spread
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: nginx-soft-spread

      containers:
        - name: nginx
          image: nginx:1.27
```

Apply:

```bash
kubectl apply -f nginx-soft-spread.yaml
```

Verify:

```bash
kubectl get pods -n topology-demo -o wide
```

The scheduler prefers a balanced distribution but does not block scheduling solely because the spread constraint cannot be satisfied.

## 8. Node-Level Topology Spread

You can distribute application replicas across individual worker nodes rather than availability zones.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-node-spread
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-node-spread
  template:
    metadata:
      labels:
        app: nginx-node-spread
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: nginx-node-spread

      containers:
        - name: nginx
          image: nginx:1.27
```

This encourages replicas to be distributed across different worker nodes.

## 9. Combining Node and Zone Topology Spread

In production environments, you may want to distribute Pods across both nodes and availability zones.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
spec:
  replicas: 6
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: production-app

        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: production-app

      containers:
        - name: nginx
          image: nginx:1.27
```

This configuration:

1. Requires balanced distribution across eligible zones.
2. Prefers distribution across individual worker nodes.
3. Uses a hard zone-level constraint and a soft node-level constraint.

The cluster must have sufficient eligible nodes and capacity to satisfy the hard constraint.

## 10. Topology Spread Constraints in AKS

AKS supports topology spread constraints through standard Kubernetes Pod specifications.

In a multi-zone AKS cluster, nodes are assigned zone labels when deployed in availability-zone-enabled configurations.

Check node labels:

```bash
kubectl get nodes \
  -L topology.kubernetes.io/zone
```

Example output:

```text
NAME                              ZONE
aks-systempool-xxxx-vmss000000    centralindia-1
aks-systempool-xxxx-vmss000001    centralindia-2
aks-systempool-xxxx-vmss000002    centralindia-3
```

Actual zone values depend on the Azure region and cluster configuration.

### Example AKS Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-production-app
  namespace: default
spec:
  replicas: 6
  selector:
    matchLabels:
      app: aks-production-app
  template:
    metadata:
      labels:
        app: aks-production-app
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: aks-production-app

      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
```

Apply:

```bash
kubectl apply -f aks-production-app.yaml
```

Verify:

```bash
kubectl get pods -o wide
```

Check distribution:

```bash
kubectl get nodes \
  -L topology.kubernetes.io/zone
```

**AKS production considerations:**

- Use availability-zone-enabled node pools where supported.
- Verify that the cluster has nodes in the required zones.
- Ensure sufficient CPU and memory capacity in each zone.
- Use PodDisruptionBudgets for voluntary disruption protection.
- Use Cluster Autoscaler where appropriate.
- Combine topology spread constraints with appropriate storage and network architecture.

## 11. Understanding minDomains

`minDomains` specifies the minimum number of eligible topology domains required for a topology spread constraint.

Example:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    minDomains: 3
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: nginx
```

Suppose only two eligible zones are available, even though `minDomains` is set to three.

For the skew calculation, Kubernetes uses a global minimum of zero because fewer than three eligible domains exist.

As a result, scheduling may be blocked even when the two available zones have matching Pods.

Use `minDomains` when the application must be spread across a minimum number of failure domains.

## 12. Understanding nodeAffinityPolicy and nodeTaintsPolicy

These parameters determine how Kubernetes calculates eligible topology domains.

Example:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    nodeAffinityPolicy: Honor
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels:
        app: nginx
```

### nodeAffinityPolicy

- `Honor`: Considers the Pod's node affinity and node selector when determining eligible nodes.
- `Ignore`: Does not use those constraints when calculating eligible domains.

### nodeTaintsPolicy

- `Honor`: Considers node taints when determining eligible nodes.
- `Ignore`: Does not use node taints when calculating eligible domains.

These settings are useful when workloads are restricted to particular node pools.

## 13. Difference Between Topology Spread Constraints and Pod Anti-Affinity

| Feature | Topology Spread Constraints | Pod Anti-Affinity |
|---|---|---|
| Purpose | Distribute Pods evenly | Avoid placing matching Pods together |
| Distribution | Controls skew across domains | Prevents or discourages co-location |
| Hard rule | DoNotSchedule | requiredDuringSchedulingIgnoredDuringExecution |
| Soft rule | ScheduleAnyway | preferredDuringSchedulingIgnoredDuringExecution |
| Node-level placement | Supported | Supported |
| Zone-level placement | Supported | Supported |
| Best use case | Balanced replica distribution | Workload isolation and separation |

**Recommendation:** Use Topology Spread Constraints when you want controlled, balanced distribution across nodes or availability zones.

## 14. Troubleshooting

### Issue 1: Pods Stuck in Pending

Possible reasons:

- Not enough eligible topology domains.
- `maxSkew` requirement cannot be satisfied.
- Required node affinity excludes nodes.
- Node taints exclude nodes.
- Insufficient CPU or memory.
- Missing topology labels.

Check:

```bash
kubectl describe pod <POD_NAME>
```

Inspect the Events section.

### Issue 2: Zone Labels Are Missing

Check:

```bash
kubectl get nodes \
  -L topology.kubernetes.io/zone
```

If the zone labels are missing, the cluster may not have zone-aware node configuration.

For KIND labs, you can manually apply simulated zone labels.

### Issue 3: Pods Are Not Evenly Distributed

Check:

- The `labelSelector` matches the intended Pods.
- The `topologyKey` exists on eligible nodes.
- The `whenUnsatisfiable` setting.
- The number of eligible topology domains.
- Node affinity and taint policies.

### Issue 4: One Zone Has No Pods

Check:

```bash
kubectl get nodes \
  -L topology.kubernetes.io/zone

kubectl get pods -o wide
```

A zone may have no eligible nodes or insufficient resources.

### Useful Commands

```bash
# List nodes with zone labels
kubectl get nodes -L topology.kubernetes.io/zone

# List nodes with hostname labels
kubectl get nodes -L kubernetes.io/hostname

# List all Pods
kubectl get pods -A -o wide

# Inspect Deployment
kubectl describe deployment <DEPLOYMENT_NAME>

# Inspect Pod scheduling events
kubectl describe pod <POD_NAME>

# View Deployment YAML
kubectl get deployment <DEPLOYMENT_NAME> -o yaml
```

## 15. Best Practices

- Use topology spread constraints for highly available applications.
- Prefer zone-level distribution for workloads requiring zone resilience.
- Use node-level distribution to reduce the impact of individual node failures.
- Choose `maxSkew` based on the application's availability requirements.
- Use `DoNotSchedule` when strict distribution is required.
- Use `ScheduleAnyway` when scheduling flexibility is more important.
- Verify topology labels before applying constraints.
- Ensure sufficient resources in every eligible topology domain.
- Combine topology spread constraints with PodDisruptionBudgets.
- Test scheduling behavior before applying changes to production clusters.

## 16. Hands-On Practice Labs

| Lab | Task |
|---|---|
| Lab 1 | Create a multi-node KIND cluster |
| Lab 2 | Add simulated zone labels to worker nodes |
| Lab 3 | Deploy six replicas across three zones |
| Lab 4 | Configure `maxSkew: 1` |
| Lab 5 | Compare DoNotSchedule and ScheduleAnyway |
| Lab 6 | Distribute replicas across worker nodes |
| Lab 7 | Combine node-level and zone-level spread constraints |
| Lab 8 | Experiment with minDomains |
| Lab 9 | Configure topology spread in AKS |
| Lab 10 | Troubleshoot Pending Pods caused by topology constraints |

## 17. Interview Questions

1. What are Kubernetes Topology Spread Constraints?
2. Why do we use topology spread constraints?
3. What is a topology domain?
4. What is the purpose of maxSkew?
5. What is the difference between DoNotSchedule and ScheduleAnyway?
6. What is the purpose of topologyKey?
7. What is the difference between hostname and zone topology keys?
8. What is minDomains?
9. How do topology spread constraints work with node affinity?
10. What is nodeTaintsPolicy?
11. How do you distribute six replicas across three availability zones?
12. What happens if one availability zone has no eligible nodes?
13. What is the difference between topology spread constraints and Pod Anti-Affinity?
14. How do you implement zone-level distribution in AKS?
15. How do topology spread constraints improve application availability?

## 18. Official Documentation

- [Kubernetes Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Kubernetes Assign Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Kubernetes Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
- [AKS Availability Zones](https://learn.microsoft.com/azure/aks/availability-zones)

---

## Conclusion

Topology Spread Constraints provide fine-grained control over how Kubernetes distributes application replicas across topology domains.
