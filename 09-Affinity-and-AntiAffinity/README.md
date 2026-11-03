# Kubernetes Node Affinity and Pod Affinity/Anti-Affinity

## 1. Introduction

Kubernetes provides scheduling mechanisms to control where Pods should run inside a cluster.

By default, the Kubernetes scheduler selects a suitable worker node based on resource availability, scheduling constraints, and other policies.

However, in real-world environments, we often need more control over Pod placement.

For example:

- Run database Pods only on nodes with SSD storage.
- Run GPU workloads on GPU-enabled nodes.
- Deploy application Pods in the same availability zone as database Pods.
- Distribute replicas across different worker nodes.
- Avoid running multiple replicas on the same node.
- Improve application availability across failure domains.

Kubernetes provides three important scheduling mechanisms:

1. **Node Affinity** – Selects nodes based on node labels.
2. **Pod Affinity** – Places Pods near other matching Pods.
3. **Pod Anti-Affinity** – Places Pods away from other matching Pods.

## 2. What Is Node Affinity?

Node Affinity is a Kubernetes scheduling feature that allows you to specify which nodes are suitable for running a Pod based on node labels.

It is an advanced alternative to `nodeSelector`.

For example, imagine your cluster has three worker nodes:

| Node | Label | Purpose |
|---|---|---|
| worker-1 | disk=ssd | Database |
| worker-2 | disk=hdd | General workloads |
| worker-3 | disk=ssd | High-performance workloads |

If you want to run a database Pod only on nodes with SSD storage, you can use Node Affinity.

### Node Affinity Types

Kubernetes supports two primary types:

| Type | Behavior |
|---|---|
| requiredDuringSchedulingIgnoredDuringExecution | Hard requirement |
| preferredDuringSchedulingIgnoredDuringExecution | Soft preference |

### 2.1 Required Node Affinity

This is a hard scheduling requirement.

If no node matches the configured rules, the Pod remains Pending.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-required-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disk
                operator: In
                values:
                  - ssd

  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Explanation:

- `nodeAffinity`: Defines node placement rules.
- `requiredDuringSchedulingIgnoredDuringExecution`: Requires a matching node during scheduling.
- `nodeSelectorTerms`: Contains scheduling expressions.
- `matchExpressions`: Defines label matching conditions.
- `key: disk`: Checks the node's disk label.
- `operator: In`: Requires the label value to be in the specified list.
- `values: [ssd]`: Matches nodes with `disk=ssd`.

Apply:

```bash
kubectl apply -f nginx-required-affinity.yaml
```

Verify:

```bash
kubectl get pods -o wide
```

The Pod can run only on a node labeled `disk=ssd`.

### 2.2 Preferred Node Affinity

This is a soft scheduling preference.

The scheduler prefers nodes that match the rule, but it can schedule the Pod on another suitable node if necessary.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-preferred-affinity
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchExpressions:
              - key: disk
                operator: In
                values:
                  - ssd

  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Explanation:

- `preferredDuringSchedulingIgnoredDuringExecution`: Defines a scheduling preference.
- `weight: 80`: Assigns a preference weight from 1 to 100.
- `preference`: Contains the matching rules.
- Nodes matching the preference receive a scheduling score advantage.

**Important:** A preferred rule does not guarantee placement on an SSD node.

## 3. Node Affinity Operators

Node Affinity supports several operators.

| Operator | Description |
|---|---|
| In | Label value must match one of the specified values |
| NotIn | Label value must not match any specified value |
| Exists | Label key must exist |
| DoesNotExist | Label key must not exist |
| Gt | Numeric label value must be greater than the specified value |
| Lt | Numeric label value must be less than the specified value |

Example using `NotIn`:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: environment
              operator: NotIn
              values:
                - dev
```

This excludes nodes with `environment=dev`.

**Note:** Multiple expressions within one `matchExpressions` list are evaluated with AND logic. Multiple `nodeSelectorTerms` are evaluated with OR logic.

## 4. What Is Pod Affinity?

Pod Affinity allows the Kubernetes scheduler to place a Pod close to other Pods based on their labels and topology.

For example:

- Place an application Pod in the same availability zone as its database Pod.
- Run a frontend Pod in the same zone as a backend Pod.
- Keep tightly coupled workloads within the same topology domain.

Pod Affinity uses:

- `labelSelector`
- `topologyKey`
- `requiredDuringSchedulingIgnoredDuringExecution`
- `preferredDuringSchedulingIgnoredDuringExecution`

### 4.1 Required Pod Affinity

This is a hard scheduling requirement.

The Pod can be scheduled only in a topology domain containing matching Pods.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  labels:
    app: backend
spec:
  containers:
    - name: nginx
      image: nginx:1.27
```

Create the frontend Pod with Pod Affinity:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: backend
          topologyKey: kubernetes.io/hostname

  containers:
    - name: nginx
      image: nginx:1.27
```

Explanation:

- `podAffinity`: Enables Pod Affinity rules.
- `labelSelector`: Identifies the Pods to colocate with.
- `matchLabels`: Matches Pods labeled `app=backend`.
- `topologyKey`: Defines the topology domain.
- `kubernetes.io/hostname`: Requires the matching Pod to be on the same node.

**Important:** The backend Pod must already be running or scheduled successfully for this example to work. Both Pods must also be in the same namespace unless the affinity rule specifies other namespaces.

### 4.2 Preferred Pod Affinity

This is a soft scheduling preference.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-preferred
spec:
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app: backend
            topologyKey: topology.kubernetes.io/zone

  containers:
    - name: nginx
      image: nginx:1.27
```

The scheduler prefers a topology zone containing matching backend Pods but can select another suitable zone.

## 5. What Is Pod Anti-Affinity?

Pod Anti-Affinity tells Kubernetes to avoid placing matching Pods in the same topology domain.

It is useful for high availability and workload distribution.

For example, suppose you have three replicas of a frontend application.

Without Pod Anti-Affinity, all replicas might run on the same worker node.

If that node fails, all three replicas may become unavailable.

With Pod Anti-Affinity, you can distribute replicas across different nodes or zones.

### 5.1 Required Pod Anti-Affinity

This is a hard scheduling rule.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ha
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-ha
  template:
    metadata:
      labels:
        app: nginx-ha
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: nginx-ha
              topologyKey: kubernetes.io/hostname

      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Explanation:

- `podAntiAffinity`: Enables Pod Anti-Affinity.
- `labelSelector`: Identifies matching Pods.
- `app: nginx-ha`: Matches replicas belonging to this Deployment.
- `topologyKey: kubernetes.io/hostname`: Prevents matching replicas from sharing the same node.

Expected behavior:

| Worker Node | Pod |
|---|---|
| worker-1 | nginx-ha-1 |
| worker-2 | nginx-ha-2 |
| worker-3 | nginx-ha-3 |

The actual placement depends on available nodes and resources.

If only two eligible nodes exist, the third replica remains Pending.

### 5.2 Preferred Pod Anti-Affinity

This is a soft scheduling preference.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-preferred-ha
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-preferred-ha
  template:
    metadata:
      labels:
        app: nginx-preferred-ha
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: nginx-preferred-ha
                topologyKey: kubernetes.io/hostname

      containers:
        - name: nginx
          image: nginx:1.27
```

The scheduler prefers to distribute replicas across different nodes but can place multiple replicas on one node if necessary.

## 6. Understanding topologyKey

The `topologyKey` defines the topology domain used by Pod Affinity and Pod Anti-Affinity.

Common topology labels include:

| Topology Key | Meaning |
|---|---|
| kubernetes.io/hostname | Individual worker node |
| topology.kubernetes.io/zone | Availability zone |
| topology.kubernetes.io/region | Azure or cloud region |

Example:

```yaml
topologyKey: kubernetes.io/hostname
```

This controls placement at the node level.

Example:

```yaml
topologyKey: topology.kubernetes.io/zone
```

This controls placement at the availability-zone level.

For zone-level placement, nodes must have the appropriate zone labels.

Verify node labels:

```bash
kubectl get nodes --show-labels
```

## 7. Difference Between Node Affinity, Pod Affinity, and Pod Anti-Affinity

| Feature | Node Affinity | Pod Affinity | Pod Anti-Affinity |
|---|---|---|---|
| Purpose | Select nodes | Place Pods near matching Pods | Place Pods away from matching Pods |
| Matches | Node labels | Pod labels | Pod labels |
| Applied to | Pod specification | Pod specification | Pod specification |
| Common use case | GPU or SSD nodes | Application and database colocation | High availability |
| Topology key | Not required | Required | Required |
| Hard and soft rules | Yes | Yes | Yes |

## 8. Hands-On Lab: Node Affinity Using KIND

Let's implement Node Affinity on a local KIND cluster.

### Prerequisites

- Docker Desktop
- KIND
- kubectl
- A running KIND cluster

Check your cluster:

```bash
kubectl get nodes
```

If you need a cluster:

```bash
kind create cluster --name affinity-lab --config kind-multi-node.yaml
```

### Step 1: Label Worker Nodes

List nodes:

```bash
kubectl get nodes
```

Apply labels:

```bash
kubectl label nodes affinity-lab-worker disk=ssd
kubectl label nodes affinity-lab-worker2 disk=hdd
```

Replace node names with the actual names in your cluster.

Verify:

```bash
kubectl get nodes --show-labels
```

### Step 2: Create a Pod With Required Node Affinity

Create `node-affinity.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-ssd
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disk
                operator: In
                values:
                  - ssd

  containers:
    - name: nginx
      image: nginx:1.27
```

Apply:

```bash
kubectl apply -f node-affinity.yaml
```

Verify:

```bash
kubectl get pod nginx-ssd -o wide
```

Expected: The Pod runs on the worker node labeled `disk=ssd`.

### Step 3: Test Preferred Node Affinity

Create a Pod with a preferred SSD rule.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-preferred-ssd
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: disk
                operator: In
                values:
                  - ssd

  containers:
    - name: nginx
      image: nginx:1.27
```

Apply:

```bash
kubectl apply -f preferred-node-affinity.yaml
```

Verify:

```bash
kubectl get pods -o wide
```

The scheduler prefers the SSD node but can use another suitable node.

## 9. Hands-On Lab: Pod Affinity Using KIND

### Step 1: Deploy a Backend Pod

Create `backend-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  labels:
    app: backend
spec:
  containers:
    - name: nginx
      image: nginx:1.27
```

Apply:

```bash
kubectl apply -f backend-pod.yaml
```

Verify:

```bash
kubectl get pods -o wide --show-labels
```

### Step 2: Deploy a Frontend Pod With Pod Affinity

Create `frontend-affinity.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: backend
          topologyKey: kubernetes.io/hostname

  containers:
    - name: nginx
      image: nginx:1.27
```

Apply:

```bash
kubectl apply -f frontend-affinity.yaml
```

Verify:

```bash
kubectl get pods -o wide
```

The frontend and backend Pods should run on the same node, provided the backend Pod is scheduled and all other scheduling requirements are satisfied.

## 10. Hands-On Lab: Pod Anti-Affinity Using KIND

### Step 1: Create a Deployment

Create `pod-anti-affinity.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ha
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-ha
  template:
    metadata:
      labels:
        app: nginx-ha
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: nginx-ha
              topologyKey: kubernetes.io/hostname

      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f pod-anti-affinity.yaml
```

### Step 2: Verify Pod Distribution

```bash
kubectl get pods -o wide
```

Expected behavior:

- Each replica runs on a different eligible node.
- If there are fewer than three eligible nodes, some replicas remain Pending.
- The scheduler will not violate the required anti-affinity rule to place the remaining replicas.

### Step 3: Inspect Scheduling Events

```bash
kubectl describe pods
```

If a Pod is Pending, check the Events section for messages related to Pod affinity or anti-affinity.

## 11. Combining Node Affinity and Pod Anti-Affinity

In production environments, you may need to control both node selection and replica distribution.

Example:

- Run application workloads only on nodes labeled `workload=application`.
- Distribute replicas across different worker nodes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: workload
                    operator: In
                    values:
                      - application

        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: production-app
                topologyKey: kubernetes.io/hostname

      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Apply the required node labels:

```bash
kubectl label nodes <NODE_NAME> workload=application
```

This configuration:

1. Requires nodes to have `workload=application`.
2. Prefers to distribute application replicas across different nodes.
3. Allows scheduling on the same node if no better placement is available and other requirements are satisfied.

## 12. Node Affinity and Pod Affinity in AKS

In AKS, affinity rules are useful for:

- Dedicated node pools.
- Workload isolation.
- Availability-zone distribution.
- Database and application placement.
- GPU workload scheduling.

### Example: Node Affinity for an AKS User Node Pool

First, check the node labels:

```bash
kubectl get nodes --show-labels
```

AKS commonly adds this label:

```text
kubernetes.azure.com/agentpool
```

Example Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: aks-app
  template:
    metadata:
      labels:
        app: aks-app
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.azure.com/agentpool
                    operator: In
                    values:
                      - userpool

      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f aks-node-affinity.yaml
```

Verify:

```bash
kubectl get pods -o wide
```

The Pods can run only on nodes belonging to the specified node pool, assuming the label and node pool name are correct.

### Production Consideration

For AKS workloads that require high availability, consider:

- Node pools distributed across availability zones.
- Pod anti-affinity or topology spread constraints.
- PodDisruptionBudgets.
- Cluster Autoscaler.
- Resource requests and limits.
- Appropriate storage and network design.

## 13. Troubleshooting

### Issue 1: Pod Stuck in Pending

Possible causes:

- No node matches required Node Affinity.
- No matching Pod exists for required Pod Affinity.
- Pod Anti-Affinity prevents placement.
- Insufficient CPU or memory.
- Required topology labels are missing.

Check:

```bash
kubectl describe pod <POD_NAME>
```

### Issue 2: Node Affinity Is Not Working

Check node labels:

```bash
kubectl get nodes --show-labels
```

Check the Pod specification:

```bash
kubectl get pod <POD_NAME> -o yaml
```

Verify the key, operator, values, and node labels.

### Issue 3: Pod Affinity Is Not Working

Verify matching Pod labels:

```bash
kubectl get pods --show-labels -A
```

Check the namespace and topology key.

### Issue 4: Pod Anti-Affinity Causes Pending Pods

Check the number of eligible nodes:

```bash
kubectl get nodes
```

Check scheduling events:

```bash
kubectl describe pod <POD_NAME>
```

If using required anti-affinity, ensure enough eligible topology domains are available.

## 14. Difference Between Scheduling Mechanisms

| Mechanism | Scheduling Behavior |
|---|---|
| nodeSelector | Simple node-label matching |
| Node Affinity | Advanced node-label matching |
| Pod Affinity | Prefer or require placement near matching Pods |
| Pod Anti-Affinity | Prefer or require placement away from matching Pods |
| Taints | Repel Pods from nodes |
| Tolerations | Permit Pods to tolerate matching taints |
| Topology Spread Constraints | Distribute Pods across topology domains |

**Important:** Topology Spread Constraints are often a better choice when the primary objective is evenly distributing replicas across nodes or availability zones.

## 15. Hands-On Practice Labs

| Lab | Task |
|---|---|
| Lab 1 | Label worker nodes |
| Lab 2 | Configure required Node Affinity |
| Lab 3 | Configure preferred Node Affinity |
| Lab 4 | Deploy backend and frontend Pods |
| Lab 5 | Configure required Pod Affinity |
| Lab 6 | Configure preferred Pod Affinity |
| Lab 7 | Deploy three replicas with Pod Anti-Affinity |
| Lab 8 | Combine Node Affinity and Pod Anti-Affinity |
| Lab 9 | Implement node placement in AKS |
| Lab 10 | Troubleshoot Pending Pods caused by affinity rules |

## 16. Interview Questions

1. What is Node Affinity in Kubernetes?
2. What is the difference between nodeSelector and Node Affinity?
3. What are the two types of Node Affinity?
4. What is the difference between required and preferred scheduling rules?
5. What is Pod Affinity?
6. What is Pod Anti-Affinity?
7. What is the purpose of topologyKey?
8. What is the difference between `kubernetes.io/hostname` and `topology.kubernetes.io/zone`?
9. How do you distribute three application replicas across three worker nodes?
10. Can Pod Affinity and Node Affinity be used together?
11. What happens if no node satisfies required Node Affinity?
12. What happens if required Pod Anti-Affinity cannot be satisfied?
13. How do you use Node Affinity in AKS?
14. How would you deploy database and application workloads on dedicated node pools?
15. What is the difference between Pod Anti-Affinity and Topology Spread Constraints?

## 17. Best Practices

- Use Node Affinity for workload-specific node selection.
- Use Pod Affinity only when colocating workloads provides a real benefit.
- Use Pod Anti-Affinity to improve replica availability.
- Prefer soft scheduling rules when strict placement is not necessary.
- Ensure enough eligible nodes exist before using required anti-affinity.
- Use topology spread constraints when even distribution is the primary goal.
- Verify node labels before applying affinity rules.
- Combine scheduling rules with resource requests and limits.
- Test scheduling policies in a non-production environment first.

## 18. Official Documentation

- [Assign Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Inter-Pod Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Kubernetes Scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)

---

## Conclusion

Node Affinity, Pod Affinity, and Pod Anti-Affinity provide advanced control over Kubernetes workload placement.

By completing this guide, you have learned:

- How to select nodes using Node Affinity.
- How to use required and preferred scheduling rules.
- How to colocate Pods using Pod Affinity.
- How to separate replicas using Pod Anti-Affinity.
- How to use topology keys.
- How to implement workload placement in KIND and AKS.
- How to troubleshoot scheduling issues.
