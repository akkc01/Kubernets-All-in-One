# Kubernetes Taints and Tolerations

## 1. Introduction

In Kubernetes, **Taints and Tolerations** control which Pods can be scheduled on specific worker nodes.

They help administrators restrict workloads from running on particular nodes unless a Pod explicitly tolerates the node's taint.

For example:

- A dedicated node pool should run only database workloads.
- A GPU-enabled node should run only machine-learning workloads.
- A production node should reject general-purpose application Pods.
- A node with a special configuration should accept only selected workloads.

Taints and tolerations work together with the Kubernetes scheduler to control Pod placement.

## 2. What Is a Taint?

A **Taint** is a property applied to a Kubernetes node.

It tells the Kubernetes scheduler that the node should reject Pods that do not have a matching toleration.

Syntax:

```
kubectl taint nodes <NODE_NAME> key=value:effect
```

Example:

```
kubectl taint nodes worker-node-1 environment=production:NoSchedule
```

This taint means:

- Key: `environment`
- Value: `production`
- Effect: `NoSchedule`

Pods without a matching toleration will not be scheduled on this node.

## 3. What Is a Toleration?

A **Toleration** is a configuration added to a Pod specification.

It allows a Pod to be scheduled on a node with a matching taint.

Example:

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  tolerations:
    - key: "environment"
      operator: "Equal"
      value: "production"
      effect: "NoSchedule"
  containers:
    - name: nginx
      image: nginx:1.27
```

This Pod tolerates the following taint:

```
environment=production:NoSchedule
```

**Important:** A toleration does not guarantee that a Pod will be scheduled on a particular node. It only permits scheduling on nodes whose taints are tolerated. Use nodeSelector or node affinity when you also need to select a specific node or node group.

## 4. Taint Effects in Kubernetes

Kubernetes supports three taint effects.

### 4.1 NoSchedule

Prevents new Pods that do not tolerate the taint from being scheduled on the node.

Existing Pods are not automatically evicted.

Example:

```
kubectl taint nodes worker-node-1 app=database:NoSchedule
```

Behavior:

- New Pods without matching tolerations cannot be scheduled.
- Existing Pods continue running.
- Pods with matching tolerations are allowed.

### 4.2 PreferNoSchedule

This is a soft scheduling restriction.

The scheduler tries to avoid placing Pods that do not tolerate the taint on the node, but it may still schedule them if necessary.

Example:

```
kubectl taint nodes worker-node-1 app=database:PreferNoSchedule
```

Behavior:

- Scheduler prefers other suitable nodes.
- Scheduling is not strictly blocked.
- Existing Pods are not evicted.

### 4.3 NoExecute

Prevents new non-tolerating Pods from being scheduled and evicts existing non-tolerating Pods from the node.

Example:

```
kubectl taint nodes worker-node-1 maintenance=true:NoExecute
```

Behavior:

- New Pods without a matching toleration cannot be scheduled.
- Existing Pods without a matching toleration are evicted.
- Pods with matching tolerations can remain.

You can also specify `tolerationSeconds` to control how long a Pod tolerates a `NoExecute` taint before eviction.

Example:

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  tolerations:
    - key: "maintenance"
      operator: "Equal"
      value: "true"
      effect: "NoExecute"
      tolerationSeconds: 60
  containers:
    - name: nginx
      image: nginx:1.27
```

The Pod can remain on the node for up to 60 seconds after the matching `NoExecute` taint is applied. After that, it becomes eligible for eviction.

## 5. Difference Between Taints and Tolerations

| Taints                                         | Tolerations                                |
| ---------------------------------------------- | ------------------------------------------ |
| Applied to Nodes                               | Defined in Pod specifications              |
| Restrict Pod scheduling                        | Allow Pods to tolerate matching taints     |
| Used to repel workloads                        | Used to permit workloads                   |
| Controlled using kubectl or node configuration | Defined in YAML manifests                  |
| Can have three effects                         | Can match a taint's key, value, and effect |

## 6. Taint and Toleration Matching

A toleration must match the taint's key, effect, and value according to its operator.

Two commonly used operators are:

### Equal

Matches a specific key and value.

```
tolerations:
  - key: "environment"
    operator: "Equal"
    value: "production"
    effect: "NoSchedule"
```

Matches:

```
environment=production:NoSchedule
```

### Exists

Matches a taint with the specified key, regardless of its value.

```
tolerations:
  - key: "environment"
    operator: "Exists"
    effect: "NoSchedule"
```

This tolerates any value for the `environment` key with the `NoSchedule` effect.

**Note:** If `effect` is omitted in a toleration, it can match taints with any effect for that key and operator. If the key is also omitted with `operator: Exists`, the toleration matches all taint keys and values. Use broad tolerations carefully.

## 7. Hands-On Lab: Taints and Tolerations on KIND

Let's implement taints and tolerations on a local Kubernetes cluster using KIND.

### Prerequisites

- Docker Desktop
- KIND
- kubectl
- A running multi-node KIND cluster

Check your cluster:

```
kubectl get nodes
```

If you need to create a multi-node cluster, use this configuration.

Create `kind-multi-node.yaml`:

```
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
  - role: control-plane

  - role: worker

  - role: worker
```

Create the cluster:

```
kind create cluster --name taint-lab --config kind-multi-node.yaml
```

Verify:

```
kubectl get nodes -o wide
```

### Step 1: Select a Worker Node

List your nodes:

```
kubectl get nodes
```

Example:

```
NAME                        STATUS   ROLES
taint-lab-control-plane     Ready    control-plane
taint-lab-worker            Ready    <none>
taint-lab-worker2           Ready    <none>
```

Set a worker node name in your terminal:

```
NODE=taint-lab-worker
```

Use the actual node name returned by your cluster.

### Step 2: Apply a Taint

Apply a `NoSchedule` taint:

```
kubectl taint nodes $NODE environment=production:NoSchedule
```

Verify:

```
kubectl describe node $NODE
```

Look for:

```
Taints: environment=production:NoSchedule
```

### Step 3: Create a Pod Without Toleration

Create `nginx-without-toleration.yaml`:

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-without-toleration
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Apply:

```
kubectl apply -f nginx-without-toleration.yaml
```

Check:

```
kubectl get pod nginx-without-toleration -o wide
```

**Expected behavior:** The scheduler will not place this Pod on the tainted worker node. It may run on another suitable node.

If the Pod remains Pending, inspect its scheduling events:

```
kubectl describe pod nginx-without-toleration
```

### Step 4: Create a Pod With Toleration

Create `nginx-with-toleration.yaml`:

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-toleration
spec:
  tolerations:
    - key: "environment"
      operator: "Equal"
      value: "production"
      effect: "NoSchedule"

  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Apply:

```
kubectl apply -f nginx-with-toleration.yaml
```

Check:

```
kubectl get pods -o wide
```

The Pod is now permitted to run on the tainted worker node, although it may be scheduled on another suitable node.

### Step 5: Force Scheduling on the Tainted Node

To ensure the Pod runs specifically on the tainted worker, add `nodeSelector` using the node's hostname label.

First, inspect the node label:

```
kubectl get node $NODE --show-labels
```

The hostname label normally matches the node name.

Create `nginx-production.yaml`:

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-production
spec:
  nodeSelector:
    kubernetes.io/hostname: taint-lab-worker

  tolerations:
    - key: "environment"
      operator: "Equal"
      value: "production"
      effect: "NoSchedule"

  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Apply:

```
kubectl apply -f nginx-production.yaml
```

Verify:

```
kubectl get pod nginx-production -o wide
```

The `NODE` column should show the selected worker node, provided it is healthy and has sufficient resources.

**Important:** Replace `taint-lab-worker` in the YAML if your actual worker node has a different name.

## 8. Hands-On Lab: NoExecute Effect

Apply a `NoExecute` taint:

```
kubectl taint nodes $NODE maintenance=true:NoExecute
```

Inspect Pods:

```
kubectl get pods -o wide
```

Pods without a matching toleration that are running on this node become eligible for eviction.

Create a Pod with a matching toleration:

```
apiVersion: v1
kind: Pod
metadata:
  name: maintenance-pod
spec:
  nodeSelector:
    kubernetes.io/hostname: taint-lab-worker

  tolerations:
    - key: "maintenance"
      operator: "Equal"
      value: "true"
      effect: "NoExecute"

  containers:
    - name: nginx
      image: nginx:1.27
```

Apply:

```
kubectl apply -f maintenance-pod.yaml
```

Verify:

```
kubectl get pod maintenance-pod -o wide
```

The Pod can run on the selected node because it tolerates both taints applied in this lab:

- `environment=production:NoSchedule`
- `maintenance=true:NoExecute`

**Why both?** The Pod must tolerate every taint that would otherwise repel or evict it from the selected node.

## 9. Remove Taints from a Node

To remove the `NoSchedule` taint:

```
kubectl taint nodes $NODE environment=production:NoSchedule-
```

To remove the `NoExecute` taint:

```
kubectl taint nodes $NODE maintenance=true:NoExecute-
```

Verify:

```
kubectl describe node $NODE
```

The removed taints should no longer appear.

## 10. Taints and Tolerations in Production

Consider a Kubernetes cluster with three worker nodes:

| Node     | Purpose            | Taint                          |
| -------- | ------------------ | ------------------------------ |
| worker-1 | General workloads  | None                           |
| worker-2 | Database workloads | `workload=database:NoSchedule` |
| worker-3 | GPU workloads      | `workload=gpu:NoSchedule`      |

A database Pod can use:

```
tolerations:
  - key: "workload"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"

nodeSelector:
  workload: database
```

A GPU workload can use:

```
tolerations:
  - key: "workload"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"

nodeSelector:
  workload: gpu
```

For this design, apply corresponding labels to the nodes:

```
kubectl label nodes worker-2 workload=database
kubectl label nodes worker-3 workload=gpu
```

This combination provides two controls:

- **Taints and tolerations:** Control which workloads are permitted on a node.
- **Node labels and nodeSelector:** Control which node a workload selects.

## 11. Taints and Tolerations in AKS

In Azure Kubernetes Service, taints are commonly used with dedicated node pools.

Example: Create a dedicated user node pool for database workloads.

```
az aks nodepool add \
  --resource-group rg-aks-demo \
  --cluster-name aks-demo-cluster \
  --name dbpool \
  --mode User \
  --node-count 2 \
  --node-vm-size Standard_D2s_v5 \
  --node-taints workload=database:NoSchedule
```

Verify:

```
az aks nodepool show \
  --resource-group rg-aks-demo \
  --cluster-name aks-demo-cluster \
  --name dbpool \
  --query "{name:name,mode:mode,nodeTaints:nodeTaints}" \
  --output yaml
```

Verify node taints:

```
kubectl get nodes
kubectl describe nodes
```

Example database Deployment:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      tolerations:
        - key: "workload"
          operator: "Equal"
          value: "database"
          effect: "NoSchedule"

      nodeSelector:
        kubernetes.azure.com/agentpool: dbpool

      containers:
        - name: nginx
          image: nginx:1.27
```

Apply:

```
kubectl apply -f database-deployment.yaml
```

Verify:

```
kubectl get pods -o wide
```

**AKS note:** Use the actual node-pool name in the `nodeSelector`. AKS node-pool labels commonly include `kubernetes.azure.com/agentpool`. Verify the label on your nodes before deploying.

## 12. Troubleshooting

### Issue 1: Pod Stuck in Pending

Check:

```
kubectl describe pod <POD_NAME>
```

Possible reasons:

- Pod does not tolerate the node taint.
- Node selector does not match any node.
- Node has insufficient CPU or memory.
- Node is NotReady or cordoned.

### Issue 2: Pod Is Running on the Wrong Node

Check:

```
kubectl get pod <POD_NAME> -o wide
```

A toleration permits scheduling but does not select a node.

Use `nodeSelector` or node affinity to control placement.

### Issue 3: Pod Is Evicted After Applying NoExecute

Check:

```
kubectl describe pod <POD_NAME>
```

A Pod without a matching `NoExecute` toleration can be evicted when the taint is applied.

### Useful Commands

```
# List nodes
kubectl get nodes

# View node labels
kubectl get nodes --show-labels

# Inspect node taints and conditions
kubectl describe node <NODE_NAME>

# View Pod scheduling events
kubectl describe pod <POD_NAME>

# List Pods across namespaces
kubectl get pods -A -o wide

# List node taints using JSONPath
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'
```

## 13. Taints vs Node Affinity vs Tolerations

| Feature       | Purpose                                 | Applied To |
| ------------- | --------------------------------------- | ---------- |
| Taints        | Repel Pods that do not tolerate them    | Node       |
| Tolerations   | Permit Pods to run on tainted nodes     | Pod        |
| Node Selector | Select nodes using exact label matches  | Pod        |
| Node Affinity | Select nodes using flexible label rules | Pod        |

These mechanisms are complementary and can be used together.

## 14. Interview Questions

1. What are taints and tolerations in Kubernetes?
2. Why do we use taints and tolerations?
3. What are the three taint effects?
4. What is the difference between NoSchedule and NoExecute?
5. What is the difference between NoSchedule and PreferNoSchedule?
6. Does a toleration guarantee that a Pod will run on a specific node?
7. How do you apply a taint to a Kubernetes node?
8. How do you remove a taint?
9. What is the difference between the Equal and Exists operators?
10. What happens to existing Pods when a NoSchedule taint is applied?
11. What happens to existing Pods when a NoExecute taint is applied?
12. What is tolerationSeconds?
13. How do you dedicate an AKS node pool to database workloads?
14. How do taints and tolerations work with node affinity?
15. How would you troubleshoot a Pod stuck in Pending because of taints?

## 15. Best Practices

- Use taints to isolate dedicated workloads.
- Use tolerations only for workloads that should run on those nodes.
- Combine tolerations with node affinity or nodeSelector when strict placement is required.
- Avoid broad tolerations unless there is a specific operational requirement.
- Use dedicated AKS node pools for specialized workloads.
- Understand the eviction impact before applying `NoExecute`.
- Monitor node conditions and Pod scheduling events.
- Do not use taints as a replacement for Kubernetes RBAC or network security.

## 16. Official Documentation

- [Kubernetes Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Assign Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Kubernetes Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity)
- [AKS Node Pools](https://learn.microsoft.com/azure/aks/create-node-pools)

---

## Conclusion

Taints and tolerations are important Kubernetes scheduling mechanisms that help control workload placement and isolate dedicated nodes.
