# Kubernetes Resource Requests, Limits, and Quality of Service (QoS) Classes

## Table of Contents

1. [Introduction](#1-introduction)
2. [Understanding Kubernetes Resources](#2-understanding-kubernetes-resources)
3. [Resource Requests](#3-resource-requests)
4. [Resource Limits](#4-resource-limits)
5. [Requests vs Limits](#5-requests-vs-limits)
6. [CPU and Memory Units](#6-cpu-and-memory-units)
7. [Quality of Service (QoS) Classes](#7-quality-of-service-qos-classes)
8. [Practical Examples](#8-practical-examples)
9. [Configure Resource Requests and Limits](#9-configure-resource-requests-and-limits)
10. [ResourceQuota and LimitRange](#10-resourcequota-and-limitrange)
11. [Monitoring Resource Utilization](#11-monitoring-resource-utilization)
12. [Troubleshooting](#12-troubleshooting)
13. [Best Practices](#13-best-practices)
14. [Hands-on Labs](#14-hands-on-labs)
15. [Interview Questions](#15-interview-questions)
16. [Official Documentation](#16-official-documentation)

---

## 1. Introduction

Kubernetes manages workloads across multiple worker nodes. Every container running inside a Pod consumes resources such as CPU and memory.

Without resource management, one application could consume excessive resources and negatively impact other workloads running on the same node.

Kubernetes provides resource management through:

- **Resource Requests:** Minimum resource amount used for scheduling decisions.
- **Resource Limits:** Maximum resource amount a container is allowed to consume.
- **Quality of Service (QoS):** Classification used by Kubernetes to determine how Pods are treated under resource pressure.

### Why do we need resource management?

Consider a Kubernetes worker node with:

- 4 CPU cores
- 8 GiB memory

If multiple applications are deployed without resource requests and limits, one application might consume most of the available memory and cause other applications to fail.

Resource management helps with:

- Efficient resource allocation.
- Better Pod scheduling.
- Preventing uncontrolled resource consumption.
- Reducing the risk of node resource exhaustion.
- Improving application stability.
- Managing Pod eviction during resource pressure.

---

## 2. Understanding Kubernetes Resources

Kubernetes primarily manages two compute resources:

| Resource | Description | Behaviour |
|---|---|---|
| CPU | Processing capacity | Compressible |
| Memory | RAM consumption | Incompressible |

### CPU

CPU represents processing capacity.

For example:

```yaml
resources:
  requests:
    cpu: "500m"
  limits:
    cpu: "1"
```

Explanation:

- `500m` = 0.5 CPU core.
- `1` = 1 CPU core.

CPU is a compressible resource. When a container reaches its CPU limit, Kubernetes uses CPU throttling rather than terminating the container.

### Memory

Memory represents RAM consumption.

```yaml
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi"
```

Explanation:

- `256Mi` = 256 mebibytes.
- `512Mi` = 512 mebibytes.

Memory is an incompressible resource. If a container exceeds its memory limit, it may be terminated by the Linux kernel's Out Of Memory (OOM) mechanism.

---

## 3. Resource Requests

A resource request specifies the amount of CPU or memory Kubernetes uses when making scheduling decisions for a container.

The Kubernetes scheduler checks resource requests against the available allocatable resources on worker nodes.

### Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-request-demo
spec:
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "250m"
          memory: "128Mi"
```

In this example:

- The container requests 250 millicores of CPU.
- The container requests 128 MiB of memory.
- The scheduler considers these requests when selecting a node.

### Important points

1. Requests are used for scheduling decisions.
2. Requests are not generally hard runtime usage caps.
3. A container can use more CPU or memory than its request if resources are available and no applicable limit prevents it.
4. The scheduler considers existing resource requests, not just current utilization.

### Example: Node scheduling

Assume a worker node has 4 CPU cores and 8 GiB of allocatable memory.

| Pod | CPU Request | Memory Request |
|---|---:|---:|
| Pod-A | 1 CPU | 2 GiB |
| Pod-B | 1 CPU | 2 GiB |
| Pod-C | 500m | 1 GiB |
| Total | 2.5 CPU | 5 GiB |

The scheduler can consider placing additional Pods on this node if sufficient allocatable resources remain and other scheduling constraints are satisfied.

---

## 4. Resource Limits

A resource limit defines the maximum CPU or memory a container can consume.

### Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-limit-demo
spec:
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "250m"
          memory: "128Mi"
        limits:
          cpu: "500m"
          memory: "256Mi"
```

In this example:

| Resource | Request | Limit |
|---|---:|---:|
| CPU | 250m | 500m |
| Memory | 128Mi | 256Mi |

### What happens when a container reaches its CPU limit?

CPU is compressible.

When a container tries to consume more CPU than its configured limit, it is throttled by the container runtime's Linux resource controls.

The container continues running, but its CPU execution is restricted.

### What happens when a container exceeds its memory limit?

Memory is incompressible.

If a container exceeds its memory limit, it can be terminated by the Linux OOM killer.

You may see:

```text
Reason: OOMKilled
Exit Code: 137
```

Check the container's termination status:

```bash
kubectl describe pod nginx-limit-demo
```

You can also inspect the previous container's logs:

```bash
kubectl logs nginx-limit-demo --previous
```

---

## 5. Requests vs Limits

| Feature | Requests | Limits |
|---|---|---|
| Purpose | Scheduling decisions | Runtime resource restriction |
| CPU | Scheduling reservation | CPU throttling |
| Memory | Scheduling reservation | Can trigger OOM termination |
| Mandatory | No, unless enforced by policy or admission configuration | No, unless enforced by policy or admission configuration |
| Can usage exceed it? | Yes | Normally no; memory may trigger OOM termination and CPU is throttled |
| Used by scheduler | Yes | Not directly for normal placement decisions |

### Real-world example

Consider an application with:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

This means:

- Kubernetes schedules the Pod using 500m CPU and 512Mi memory as its resource requests.
- The container can use up to 1 CPU core.
- The container can use up to 1 GiB of memory before the memory limit becomes enforceable through OOM handling.

---

## 6. CPU and Memory Units

### CPU units

| Value | Meaning |
|---|---|
| `1` | 1 CPU core |
| `500m` | 0.5 CPU core |
| `250m` | 0.25 CPU core |
| `100m` | 0.1 CPU core |
| `2000m` | 2 CPU cores |

`m` stands for millicpu.

### Memory units

Kubernetes supports decimal and binary memory units.

| Unit | Meaning |
|---|---|
| `1K` | 1,000 bytes |
| `1M` | 1,000,000 bytes |
| `1G` | 1,000,000,000 bytes |
| `1Ki` | 1,024 bytes |
| `1Mi` | 1,024 KiB |
| `1Gi` | 1,024 MiB |

**Important:** `1G` and `1Gi` are not equivalent.

For most Kubernetes memory configurations, binary units such as `Mi` and `Gi` are commonly used.

---

## 7. Quality of Service (QoS) Classes

Kubernetes automatically assigns every Pod one of three QoS classes:

1. Guaranteed
2. Burstable
3. BestEffort

QoS classification is based on the resource requests and limits of containers in the Pod.

QoS classification affects the order in which Pods are considered for eviction during node resource pressure. It does not guarantee that a Pod will never be evicted.

### 7.1 Guaranteed QoS

A Pod receives Guaranteed QoS when every container has:

- CPU request equal to CPU limit.
- Memory request equal to memory limit.
- Both CPU and memory requests and limits specified.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed-pod
spec:
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
```

Verify:

```bash
kubectl get pod guaranteed-pod -o jsonpath='{.status.qosClass}'
```

Output:

```text
Guaranteed
```

**Characteristics:**

- Requests equal limits for CPU and memory.
- Highest QoS class for eviction priority.
- Not immune to eviction or OOM termination.
- Useful for workloads that require predictable resource allocation.

### 7.2 Burstable QoS

A Pod receives Burstable QoS when it does not qualify for Guaranteed QoS but at least one container has a CPU or memory request or limit specified.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: burstable-pod
spec:
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "250m"
          memory: "128Mi"
        limits:
          cpu: "500m"
          memory: "256Mi"
```

Verify:

```bash
kubectl get pod burstable-pod -o jsonpath='{.status.qosClass}'
```

Output:

```text
Burstable
```

**Characteristics:**

- Requests and limits can be different.
- Resource usage can burst above requests when capacity and limits permit.
- Eviction priority generally falls between Guaranteed and BestEffort.
- Suitable for most general-purpose application workloads.

### 7.3 BestEffort QoS

A Pod receives BestEffort QoS when none of its containers specifies CPU or memory requests or limits.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: besteffort-pod
spec:
  containers:
    - name: nginx
      image: nginx:latest
```

Verify:

```bash
kubectl get pod besteffort-pod -o jsonpath='{.status.qosClass}'
```

Output:

```text
BestEffort
```

**Characteristics:**

- No CPU or memory requests or limits are specified.
- No resource request is accounted for during scheduling for these resources.
- Highest eviction priority under node pressure, all else being equal.
- Not recommended for critical production workloads.

### QoS comparison

| Feature | Guaranteed | Burstable | BestEffort |
|---|---|---|---|
| CPU request | Required | Optional | Not specified |
| CPU limit | Required | Optional | Not specified |
| Memory request | Required | Optional | Not specified |
| Memory limit | Required | Optional | Not specified |
| Request equals limit | Yes, for CPU and memory | Not necessarily | N/A |
| Eviction priority | Lowest | Medium | Highest |

**Important:** Kubernetes eviction decisions also depend on factors such as whether a Pod is using more resources than its requests and its PriorityClass. QoS is not the only factor.

---

## 8. Practical Examples

### Example 1: Guaranteed Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-guaranteed
spec:
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "1"
          memory: "512Mi"
        limits:
          cpu: "1"
          memory: "512Mi"
```

### Example 2: Burstable Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-burstable
spec:
  containers:
    - name: nginx
      image: nginx:latest
      resources:
        requests:
          cpu: "250m"
          memory: "128Mi"
        limits:
          cpu: "1"
          memory: "512Mi"
```

### Example 3: BestEffort Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-besteffort
spec:
  containers:
    - name: nginx
      image: nginx:latest
```

### Deploy all examples

```bash
kubectl apply -f guaranteed.yaml
kubectl apply -f burstable.yaml
kubectl apply -f besteffort.yaml
```

Check QoS classes:

```bash
kubectl get pods
```

```bash
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

Expected output:

```text
NAME               QOS
nginx-guaranteed   Guaranteed
nginx-burstable    Burstable
nginx-besteffort   BestEffort
```

---

## 9. Configure Resource Requests and Limits

### Example: Production-style Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: resource-demo
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
          resources:
            requests:
              cpu: "250m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "256Mi"
```

Create the namespace:

```bash
kubectl create namespace resource-demo
```

Deploy the application:

```bash
kubectl apply -f nginx-deployment.yaml
```

Verify:

```bash
kubectl get pods -n resource-demo
kubectl describe deployment nginx-deployment -n resource-demo
```

Check resource requests and limits:

```bash
kubectl get pods -n resource-demo -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}{"Requests: "}{.resources.requests}{" Limits: "}{.resources.limits}{"\n"}{end}{end}'
```

---

## 10. ResourceQuota and LimitRange

Kubernetes provides two additional mechanisms for managing resource consumption at the namespace level.

### 10.1 ResourceQuota

ResourceQuota limits the total amount of resources that can be consumed by objects in a namespace.

Example:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: resource-demo
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "2Gi"
    limits.cpu: "4"
    limits.memory: "4Gi"
    pods: "10"
```

Apply:

```bash
kubectl apply -f resource-quota.yaml
```

Check:

```bash
kubectl get resourcequota -n resource-demo
kubectl describe resourcequota compute-quota -n resource-demo
```

This quota limits the aggregate requested and limited resources across applicable namespace objects.

### 10.2 LimitRange

LimitRange defines default resource requests and limits, as well as minimum and maximum resource values for containers in a namespace.

Example:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: resource-demo
spec:
  limits:
    - type: Container
      default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "250m"
        memory: "256Mi"
      min:
        cpu: "100m"
        memory: "64Mi"
      max:
        cpu: "2"
        memory: "2Gi"
```

Apply:

```bash
kubectl apply -f limit-range.yaml
```

Verify:

```bash
kubectl get limitrange -n resource-demo
kubectl describe limitrange container-limits -n resource-demo
```

### ResourceQuota vs LimitRange

| Feature | ResourceQuota | LimitRange |
|---|---|---|
| Scope | Namespace | Namespace |
| Purpose | Aggregate resource consumption | Per-container or per-Pod defaults and bounds |
| Default requests | No | Yes |
| Default limits | No | Yes |
| Maximum values | Aggregate quota | Per-object constraints |

---

## 11. Monitoring Resource Utilization

To monitor CPU and memory usage, Kubernetes provides the `kubectl top` command when the Metrics Server is installed and working.

Check Metrics Server:

```bash
kubectl get deployment metrics-server -n kube-system
```

View node utilization:

```bash
kubectl top nodes
```

View Pod utilization:

```bash
kubectl top pods -n resource-demo
```

View container-level utilization:

```bash
kubectl top pods -n resource-demo --containers
```

Example output:

```text
NAME               CPU(cores)   MEMORY(bytes)
nginx-deployment   5m           12Mi
```

**Important:** `kubectl top` reports observed resource usage. It does not show configured requests and limits. Use `kubectl describe pod` or inspect the Pod specification to see those values.

For production monitoring, Prometheus and Grafana can provide historical metrics, dashboards, and alerts.

---

## 12. Troubleshooting

### Issue 1: Pod stuck in Pending

Check:

```bash
kubectl describe pod <pod-name>
```

Possible event:

```text
Warning  FailedScheduling
0/3 nodes are available: Insufficient cpu.
```

**Reason:** The scheduler cannot find a node with enough allocatable CPU or memory for the Pod's requests, or another scheduling constraint prevents placement.

**Solution:**

- Review Pod resource requests.
- Check node allocatable resources.
- Add or scale worker nodes if necessary.
- Review node selectors, affinity, taints, and topology constraints.

### Issue 2: OOMKilled

Check:

```bash
kubectl describe pod <pod-name>
```

Possible output:

```text
Last State: Terminated
Reason: OOMKilled
Exit Code: 137
```

**Reason:** The container was terminated due to an out-of-memory condition.

**Solution:**

- Review application memory consumption.
- Investigate memory leaks.
- Increase the memory limit if justified.
- Optimize application memory usage.

### Issue 3: CPU throttling

A container may respond slowly even when it is not restarting.

**Reason:** Its CPU limit may be too restrictive for its workload.

**Solution:**

- Review CPU usage and throttling metrics.
- Tune CPU requests and limits.
- Consider removing or increasing the CPU limit where operationally appropriate.

### Issue 4: ResourceQuota exceeded

Possible error:

```text
exceeded quota: compute-quota
```

**Reason:** The namespace has reached its configured resource quota.

**Solution:**

```bash
kubectl describe resourcequota -n resource-demo
```

Review current usage and adjust the quota or workload resource configuration.

---

## 13. Best Practices

1. Always define CPU and memory requests for production workloads.
2. Set memory limits based on measured application requirements.
3. Set CPU limits carefully because restrictive CPU limits can cause throttling.
4. Avoid deploying critical production workloads as BestEffort.
5. Use Burstable QoS for many general-purpose applications.
6. Use Guaranteed QoS where predictable resource configuration is required.
7. Configure ResourceQuota to control namespace-level consumption.
8. Configure LimitRange to establish namespace defaults and boundaries.
9. Monitor actual CPU and memory usage before tuning requests and limits.
10. Review OOMKilled events and CPU throttling metrics regularly.
11. Include resource configuration in Helm charts and Kubernetes manifests.
12. Revisit resource settings after application upgrades and traffic changes.

---

## 14. Hands-on Labs

### Lab 1: Create three Pods with different QoS classes

Create:

- Guaranteed Pod
- Burstable Pod
- BestEffort Pod

Verify:

```bash
kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

### Lab 2: Simulate CPU throttling

Deploy a CPU-intensive application with a small CPU limit.

Observe CPU usage:

```bash
kubectl top pods
```

For actual throttling measurements, use container runtime or Prometheus metrics such as `container_cpu_cfs_throttled_seconds_total` where available.

### Lab 3: Simulate memory pressure

Deploy a test container with a deliberately small memory limit and make it allocate memory.

Observe:

```bash
kubectl describe pod <pod-name>
```

Look for:

```text
Reason: OOMKilled
```

Perform this experiment only in a test cluster.

### Lab 4: Configure ResourceQuota

Create a namespace and apply a ResourceQuota.

Deploy multiple Pods and observe what happens when the namespace quota is exceeded.

### Lab 5: Configure LimitRange

Create a LimitRange with default CPU and memory requests and limits.

Deploy a Pod without resource settings and inspect its admitted specification:

```bash
kubectl get pod <pod-name> -o yaml
```

Observe the default values applied by the LimitRange.

---

## 15. Interview Questions

### Basic Questions

1. What are Kubernetes resource requests?
2. What are Kubernetes resource limits?
3. What is the difference between requests and limits?
4. What is CPU throttling?
5. What is OOMKilled?
6. What are Kubernetes QoS classes?
7. How many QoS classes are available in Kubernetes?
8. What is the difference between Guaranteed and Burstable QoS?
9. What happens when a container exceeds its memory limit?
10. What is the purpose of ResourceQuota?

### Scenario-Based Questions

**Q1. Your Pod is stuck in Pending. How would you troubleshoot it?**

Check Pod events using `kubectl describe pod`. Investigate insufficient CPU or memory, node allocatable capacity, and scheduling constraints.

**Q2. Your application is frequently restarting with OOMKilled. What would you do?**

Inspect termination status, review memory consumption and application logs, investigate memory leaks, and tune memory requests and limits based on actual workload requirements.

**Q3. Your application is slow, but CPU usage is not reaching 100%. What could be the reason?**

The container might be experiencing CPU throttling due to a restrictive CPU limit. Review throttling metrics and tune the CPU configuration.

**Q4. Can a container use more CPU than its CPU request?**

Yes. A request is used for scheduling and is not a hard CPU usage limit. The container can use additional CPU capacity when available, subject to its CPU limit.

**Q5. Can a container use more memory than its memory request?**

Yes. A memory request is not a hard runtime cap. The container can consume additional memory, subject to its memory limit and available node resources.

**Q6. Which QoS class receives the lowest eviction priority under node pressure?**

Guaranteed generally has the lowest eviction priority, followed by Burstable and then BestEffort, all else being equal.

**Q7. Does Guaranteed QoS mean a Pod can never be evicted?**

No. Guaranteed QoS does not provide immunity from eviction, node failure, or OOM termination.

**Q8. What is the difference between ResourceQuota and LimitRange?**

ResourceQuota controls aggregate resource consumption across a namespace. LimitRange defines per-container or per-Pod defaults and resource boundaries.

**Q9. If a Pod has two containers, how is its QoS class determined?**

Kubernetes evaluates all containers in the Pod. Every container must satisfy the Guaranteed requirements for the Pod to receive Guaranteed QoS.

**Q10. How would you determine the correct CPU and memory requests for a production application?**

Use historical monitoring data, load testing, peak usage, application characteristics, and operational headroom. Tune requests and limits based on measured behaviour rather than arbitrary values.

---

## 16. Official Documentation

- [Kubernetes - Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Kubernetes - Configure Quality of Service for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- [Kubernetes - Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Kubernetes - Limit Ranges](https://kubernetes.io/docs/concepts/policy/limit-range/)
- [Kubernetes - Node-pressure Eviction](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/)
- [Kubernetes - Assign Memory Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/)
- [Kubernetes - Assign CPU Resources to Containers and Pods](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/)

---

## Conclusion

Resource Requests, Limits, and QoS Classes are fundamental concepts for managing Kubernetes workloads efficiently.

Remember these three points:

- **Requests:** Used by the scheduler to make placement decisions.
- **Limits:** Restrict container resource consumption.
- **QoS:** Determines the Pod's service quality classification and contributes to eviction behaviour under resource pressure.
