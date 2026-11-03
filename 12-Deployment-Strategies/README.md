# Kubernetes Deployment Strategies — Rolling Updates, Recreate, Rollback, Canary, Blue-Green, and Revision History

## Table of Contents

1. [Introduction](#1-introduction)
2. [What Is a Kubernetes Deployment?](#2-what-is-a-kubernetes-deployment)
3. [Rolling Update Strategy](#3-rolling-update-strategy)
4. [Recreate Strategy](#4-recreate-strategy)
5. [Rollback in Kubernetes](#5-rollback-in-kubernetes)
6. [Canary Deployment](#6-canary-deployment)
7. [Blue-Green Deployment](#7-blue-green-deployment)
8. [Deployment Revision History](#8-deployment-revision-history)
9. [Rolling Update vs Recreate vs Canary vs Blue-Green](#9-rolling-update-vs-recreate-vs-canary-vs-blue-green)
10. [Hands-on Labs](#10-hands-on-labs)
11. [Troubleshooting](#11-troubleshooting)
12. [Best Practices](#12-best-practices)
13. [Common Interview Questions](#13-common-interview-questions)
14. [Official Documentation](#14-official-documentation)

---

## 1. Introduction

In Kubernetes, applications are frequently updated with new versions to introduce features, fix bugs, and improve performance.

However, deploying a new application version without planning can cause:

- Application downtime.
- Failed deployments.
- Unavailable application replicas.
- Unexpected application behaviour.
- Difficulties recovering from a failed release.

Kubernetes supports different deployment strategies to control how application versions are introduced.

### Deployment Strategies Covered

| Strategy | Description |
|---|---|
| Rolling Update | Gradually replaces old Pods with new Pods. |
| Recreate | Terminates old Pods before creating new Pods. |
| Rollback | Returns a Deployment to a previous revision. |
| Canary | Gradually exposes a new version to a selected portion of traffic. |
| Blue-Green | Maintains two environments and switches traffic between them. |
| Revision History | Maintains Deployment rollout history for inspection and rollback. |

**Important:** Rolling Update and Recreate are native Kubernetes Deployment strategies. Canary and Blue-Green are deployment patterns that can be implemented using Kubernetes resources, traffic routing, or deployment tools.

---

## 2. What Is a Kubernetes Deployment?

A Deployment is a Kubernetes workload resource that manages ReplicaSets and provides declarative updates for Pods.

It helps you:

- Deploy application replicas.
- Update container images.
- Scale applications.
- Perform rolling updates.
- Roll back failed releases.
- Maintain rollout history.

### Deployment Architecture

```text
             Kubernetes Deployment
                       |
                       v
                  ReplicaSet
                       |
              +--------+--------+
              |        |        |
              v        v        v
             Pod      Pod      Pod
```

During an update, Kubernetes creates a new ReplicaSet and gradually scales it up while scaling down the old ReplicaSet.

---

## 3. Rolling Update Strategy

### What Is a Rolling Update?

Rolling Update is the default Deployment strategy in Kubernetes.

It gradually replaces existing Pods with new Pods without intentionally stopping the entire application at once.

**Example scenario:**

Suppose you have an Nginx application running with three replicas.

```text
Before Update:

nginx:v1    nginx:v1    nginx:v1
  Pod 1       Pod 2       Pod 3
```

You update the application image from `nginx:v1` to `nginx:v2`.

Kubernetes gradually replaces the old Pods.

```text
During Update:

nginx:v2    nginx:v1    nginx:v1
  Pod 1       Pod 2       Pod 3
```

```text
During Update:

nginx:v2    nginx:v2    nginx:v1
  Pod 1       Pod 2       Pod 3
```

```text
After Update:

nginx:v2    nginx:v2    nginx:v2
  Pod 1       Pod 2       Pod 3
```

### Rolling Update YAML

Create `rolling-update.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-rolling
spec:
  replicas: 3

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1

  selector:
    matchLabels:
      app: nginx-rolling

  template:
    metadata:
      labels:
        app: nginx-rolling

    spec:
      containers:
        - name: nginx
          image: nginx:1.26
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f rolling-update.yaml
```

Check Deployment:

```bash
kubectl get deployment nginx-rolling
```

Check ReplicaSets:

```bash
kubectl get rs
```

Check Pods:

```bash
kubectl get pods -o wide
```

### Important Rolling Update Parameters

Two important parameters control the update process.

#### 1. maxSurge

Defines the maximum number of Pods that can be created above the desired replica count during a rolling update.

Example:

```yaml
replicas: 3
maxSurge: 1
```

Kubernetes can temporarily run up to four Pods during the update, assuming no other constraints prevent scheduling.

#### 2. maxUnavailable

Defines the maximum number of Pods that can be unavailable during a rolling update.

Example:

```yaml
replicas: 3
maxUnavailable: 1
```

Kubernetes can have at least two available replicas during the update.

Both parameters accept:
- An integer.
- A percentage string such as `"25%"`.

For percentage values:
- `maxSurge` rounds up.
- `maxUnavailable` rounds down.

At least one of `maxSurge` or `maxUnavailable` must be greater than zero.

### Update the Application Image

```bash
kubectl set image deployment/nginx-rolling \
  nginx=nginx:1.27
```

Monitor the rollout:

```bash
kubectl rollout status deployment/nginx-rolling
```

Check the updated image:

```bash
kubectl get deployment nginx-rolling \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Advantages

- Supports gradual application updates.
- Helps maintain application availability.
- Provides controlled replacement of Pods.
- Suitable for most stateless applications.

### Disadvantages

- Old and new versions may run simultaneously.
- Requires backward-compatible application changes.
- Deployment can become stuck if new Pods fail readiness checks.

---

## 4. Recreate Strategy

### What Is Recreate?

Recreate is a Deployment strategy in which Kubernetes terminates the existing Pods before creating the new Pods.

Unlike Rolling Update, Recreate does not gradually replace Pods.

**Example scenario:**

Suppose you have three replicas running `nginx:v1`.

When you deploy `nginx:v2`:

```text
Before Update:

nginx:v1    nginx:v1    nginx:v1
```

First, Kubernetes terminates the old Pods.

```text
During Update:

No application Pods running
```

Then Kubernetes creates the new Pods.

```text
After Update:

nginx:v2    nginx:v2    nginx:v2
```

This can cause downtime while the new Pods are starting and becoming ready.

### Recreate YAML

Create `recreate.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-recreate
spec:
  replicas: 3

  strategy:
    type: Recreate

  selector:
    matchLabels:
      app: nginx-recreate

  template:
    metadata:
      labels:
        app: nginx-recreate

    spec:
      containers:
        - name: nginx
          image: nginx:1.26
          ports:
            - containerPort: 80
```

Apply:

```bash
kubectl apply -f recreate.yaml
```

Update the image:

```bash
kubectl set image deployment/nginx-recreate \
  nginx=nginx:1.27
```

Monitor:

```bash
kubectl rollout status deployment/nginx-recreate
```

### Advantages

- Simple deployment behaviour.
- Prevents old and new versions from intentionally running together during the replacement process.
- Useful when an application cannot safely run multiple versions simultaneously.

### Disadvantages

- Causes application downtime.
- Does not provide gradual traffic migration.
- Not suitable when uninterrupted service availability is required.

**Use case:** Applications that cannot support simultaneous execution of multiple versions, provided the resulting downtime is acceptable.

---

## 5. Rollback in Kubernetes

### What Is Rollback?

Rollback means reverting a Deployment to a previously successful or desired revision.

**Example scenario:**

You deploy application version `v2`, but the application starts returning HTTP 500 errors.

You can roll back to the previous Deployment revision.

```text
Current Version:

nginx:v2
    |
    v
Application Errors
    |
    v
Rollback
    |
    v
Previous Version:

nginx:v1
```

### Check Deployment History

```bash
kubectl rollout history deployment/nginx-rolling
```

Example output:

```text
deployment.apps/nginx-rolling

REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
```

### Check a Specific Revision

```bash
kubectl rollout history deployment/nginx-rolling \
  --revision=2
```

### Perform Rollback

Roll back to the previous revision:

```bash
kubectl rollout undo deployment/nginx-rolling
```

Roll back to a specific revision:

```bash
kubectl rollout undo deployment/nginx-rolling \
  --to-revision=1
```

Verify:

```bash
kubectl rollout status deployment/nginx-rolling
```

Check the image:

```bash
kubectl get deployment nginx-rolling \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Record Change History

When applying a Deployment, you can record a change cause using:

```bash
kubectl annotate deployment nginx-rolling \
  kubernetes.io/change-cause="Updated nginx to version 1.27" \
  --overwrite
```

For reliable release auditing, also maintain version information in Git, CI/CD records, or your deployment system. The change-cause annotation is useful metadata, not a complete release audit trail.

---

## 6. Canary Deployment

### What Is Canary Deployment?

Canary deployment is a release strategy in which a new application version is introduced to a small portion of traffic before being rolled out more widely.

It helps teams validate a new version with limited production exposure.

**Example scenario:**

You have an application running with ten replicas.

- Nine replicas run version `v1`.
- One replica runs version `v2`.
- You route a small percentage of traffic to `v2`.
- You monitor logs, metrics, latency, and error rates.
- If everything works correctly, you gradually increase exposure.
- If issues occur, you remove the canary version from service.

### Canary Architecture

```text
                 User Traffic
                      |
                      v
                Kubernetes Service
                      |
              +-------+-------+
              |               |
              v               v
          Stable v1       Canary v2
          9 Replicas      1 Replica
              |               |
              v               v
          Most Traffic    Small Portion
```

**Important:** A standard Kubernetes Service does not provide an exact percentage-based traffic split. It distributes traffic across eligible endpoints; the actual distribution is not guaranteed to be exactly proportional to replica counts.

For precise traffic splitting, use a service mesh, Gateway API implementation, ingress controller, or progressive delivery tool that supports weighted routing.

### Canary Implementation Using Kubernetes Deployments

Create the stable Deployment: `canary-stable.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-stable
spec:
  replicas: 9

  selector:
    matchLabels:
      app: nginx-canary
      version: stable

  template:
    metadata:
      labels:
        app: nginx-canary
        version: stable

    spec:
      containers:
        - name: nginx
          image: nginx:1.26
          ports:
            - containerPort: 80
```

Create the canary Deployment: `canary-test.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-canary
spec:
  replicas: 1

  selector:
    matchLabels:
      app: nginx-canary
      version: canary

  template:
    metadata:
      labels:
        app: nginx-canary
        version: canary

    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

Create a Service that selects both versions: `canary-service.yaml`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-canary-service
spec:
  selector:
    app: nginx-canary

  ports:
    - port: 80
      targetPort: 80

  type: ClusterIP
```

Apply:

```bash
kubectl apply -f canary-stable.yaml
kubectl apply -f canary-test.yaml
kubectl apply -f canary-service.yaml
```

Check:

```bash
kubectl get deployments
kubectl get pods --show-labels
kubectl get service nginx-canary-service
```

The Service selects both stable and canary Pods.

### Gradually Increase the Canary Replica Count

For a simple demonstration:

```bash
kubectl scale deployment nginx-canary --replicas=2
```

Then:

```bash
kubectl scale deployment nginx-canary --replicas=5
```

This changes the number of canary endpoints, but it does not guarantee exact traffic percentages.

### Canary Rollback

If the canary version causes problems:

```bash
kubectl delete deployment nginx-canary
```

The Service will continue selecting the stable Pods.

### Production Canary Tools

For advanced traffic management, consider:

- Argo Rollouts
- Istio
- Linkerd
- Gateway API implementations with weighted routing
- Ingress controllers that support traffic splitting

---

## 7. Blue-Green Deployment

### What Is Blue-Green Deployment?

Blue-Green is a deployment strategy in which two application environments are maintained:

- **Blue:** Current production version.
- **Green:** New application version.

The new version is deployed and tested in the Green environment before production traffic is switched to it.

**Example scenario:**

Your production application currently runs `nginx:v1`.

- Blue environment runs `nginx:v1`.
- Green environment runs `nginx:v2`.
- You test Green independently.
- You update the production Service selector to point to Green.
- Production traffic now reaches `nginx:v2`.

### Blue-Green Architecture

```text
                  Users
                    |
                    v
              Kubernetes Service
                    |
             Active Selector
                    |
             +------+------+
             |             |
             v             v
          Blue v1        Green v2
          Active         Standby
```

After switching:

```text
                  Users
                    |
                    v
              Kubernetes Service
                    |
             Active Selector
                    |
             +------+------+
             |             |
             v             v
          Blue v1        Green v2
          Standby        Active
```

### Step 1: Deploy Blue Environment

Create `blue-deployment.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-blue
spec:
  replicas: 3

  selector:
    matchLabels:
      app: nginx
      version: blue

  template:
    metadata:
      labels:
        app: nginx
        version: blue

    spec:
      containers:
        - name: nginx
          image: nginx:1.26
          ports:
            - containerPort: 80
```

### Step 2: Deploy Green Environment

Create `green-deployment.yaml`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-green
spec:
  replicas: 3

  selector:
    matchLabels:
      app: nginx
      version: green

  template:
    metadata:
      labels:
        app: nginx
        version: green

    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

### Step 3: Create Production Service

Create `blue-green-service.yaml`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-production
spec:
  selector:
    app: nginx
    version: blue

  ports:
    - port: 80
      targetPort: 80

  type: ClusterIP
```

Apply all three resources:

```bash
kubectl apply -f blue-deployment.yaml
kubectl apply -f green-deployment.yaml
kubectl apply -f blue-green-service.yaml
```

### Step 4: Verify Blue Is Active

```bash
kubectl get pods --show-labels
kubectl get service nginx-production -o yaml
```

The Service selector currently points to:

```yaml
selector:
  app: nginx
  version: blue
```

### Step 5: Switch Traffic to Green

Update the Service selector:

```bash
kubectl patch service nginx-production \
  -p '{"spec":{"selector":{"app":"nginx","version":"green"}}}'
```

Verify:

```bash
kubectl get service nginx-production -o yaml
```

The Service now selects Green Pods.

### Step 6: Roll Back to Blue

If Green has a problem, switch the Service selector back:

```bash
kubectl patch service nginx-production \
  -p '{"spec":{"selector":{"app":"nginx","version":"blue"}}}'
```

### Advantages

- New version can be tested before traffic migration.
- Fast traffic switching.
- Simple application-level rollback by switching the Service selector.
- Both environments can be maintained independently.

### Disadvantages

- Requires resources for both environments.
- Database schema compatibility must be considered.
- Background jobs and external side effects need careful coordination.
- A Service selector switch is not an atomic, instantaneous cutover for every existing connection.

---

## 8. Deployment Revision History

### What Is Revision History?

Kubernetes maintains rollout history for Deployments.

Whenever a Deployment's Pod template changes, Kubernetes can create a new ReplicaSet and record a new Deployment revision.

Revision history allows administrators to:

- Inspect previous Deployment configurations.
- Identify changes between releases.
- Roll back to a previous revision.
- Investigate deployment failures.

### Check Revision History

```bash
kubectl rollout history deployment/nginx-rolling
```

### Inspect a Specific Revision

```bash
kubectl rollout history deployment/nginx-rolling \
  --revision=1
```

### Check ReplicaSets

```bash
kubectl get replicasets
```

Example:

```text
NAME                       DESIRED   CURRENT   READY
nginx-rolling-7f8d9c5b6d    3         3         3
nginx-rolling-6b7c8d9f4a    0         0         0
```

Old ReplicaSets may remain available to support rollback.

### Configure Revision History Limit

You can control how many old ReplicaSets are retained by using `revisionHistoryLimit`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-history
spec:
  replicas: 3

  revisionHistoryLimit: 5

  selector:
    matchLabels:
      app: nginx-history

  template:
    metadata:
      labels:
        app: nginx-history

    spec:
      containers:
        - name: nginx
          image: nginx:1.26
          ports:
            - containerPort: 80
```

Here:

```yaml
revisionHistoryLimit: 5
```

Kubernetes retains up to five old ReplicaSets for this Deployment, subject to the normal cleanup behaviour.

### Important Notes

- The default `revisionHistoryLimit` is 10.
- Revision history is based on changes to the Pod template.
- Scaling a Deployment does not create a new revision.
- Updating a Service selector does not create a Deployment revision.
- If `revisionHistoryLimit` is set to `0`, old ReplicaSets are not retained for rollback.

---

## 9. Rolling Update vs Recreate vs Canary vs Blue-Green

| Feature | Rolling Update | Recreate | Canary | Blue-Green |
|---|---|---|---|---|
| Deployment type | Native Deployment strategy | Native Deployment strategy | Release pattern | Release pattern |
| Gradual replacement | Yes | No | Gradual traffic exposure | No; switches between environments |
| Downtime | Can avoid downtime | Expected during replacement | Can avoid downtime | Can avoid downtime |
| Old and new versions coexist | Yes, temporarily | Not intentionally during replacement | Yes | Yes |
| Traffic control | Through available endpoints | No special traffic control | Requires traffic management for precise weights | Service or routing switch |
| Resource overhead | Moderate | Usually lower during replacement | Additional canary resources | Higher; both environments run |
| Rollback | Deployment rollback | Deployment rollback | Remove or scale down canary | Switch traffic back |

### Which Strategy Should You Choose?

| Requirement | Recommended Strategy |
|---|---|
| Standard application updates | Rolling Update |
| Application cannot run two versions together | Recreate |
| Test new version with limited production exposure | Canary |
| Test a complete new environment before cutover | Blue-Green |
| Recover from a failed Deployment update | Rollback |
| Inspect previous Deployment configurations | Revision History |

---

## 10. Hands-on Labs

### Lab 1: Perform a Rolling Update

Deploy the application:

```bash
kubectl create deployment nginx-demo \
  --image=nginx:1.26 \
  --replicas=3
```

Check:

```bash
kubectl get deployments
kubectl get pods
```

Update the image:

```bash
kubectl set image deployment/nginx-demo \
  nginx=nginx:1.27
```

Monitor:

```bash
kubectl rollout status deployment/nginx-demo
kubectl get pods -o wide
kubectl get rs
```

### Lab 2: Perform a Rollback

Check history:

```bash
kubectl rollout history deployment/nginx-demo
```

Roll back:

```bash
kubectl rollout undo deployment/nginx-demo
```

Verify:

```bash
kubectl rollout status deployment/nginx-demo

kubectl get deployment nginx-demo \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Lab 3: Test Recreate Strategy

Apply the Recreate YAML from Section 4.

Update its image:

```bash
kubectl set image deployment/nginx-recreate \
  nginx=nginx:1.27
```

Monitor the Pods:

```bash
kubectl get pods -w
```

Observe how the old Pods are terminated before the new Pods are created.

### Lab 4: Implement Canary Deployment

Apply:

```bash
kubectl apply -f canary-stable.yaml
kubectl apply -f canary-test.yaml
kubectl apply -f canary-service.yaml
```

Verify:

```bash
kubectl get deployments
kubectl get pods --show-labels
kubectl get endpointslices
```

Scale the canary:

```bash
kubectl scale deployment nginx-canary --replicas=2
```

Observe how the Service selects Pods from both versions.

### Lab 5: Implement Blue-Green Deployment

Apply:

```bash
kubectl apply -f blue-deployment.yaml
kubectl apply -f green-deployment.yaml
kubectl apply -f blue-green-service.yaml
```

Check active Service selector:

```bash
kubectl get service nginx-production -o yaml
```

Switch to Green:

```bash
kubectl patch service nginx-production \
  -p '{"spec":{"selector":{"app":"nginx","version":"green"}}}'
```

Switch back to Blue:

```bash
kubectl patch service nginx-production \
  -p '{"spec":{"selector":{"app":"nginx","version":"blue"}}}'
```

---

## 11. Troubleshooting

### Issue 1: Deployment Stuck During Rolling Update

Check:

```bash
kubectl rollout status deployment/nginx-demo
kubectl describe deployment nginx-demo
kubectl get pods
```

Possible causes:

- ImagePullBackOff.
- CrashLoopBackOff.
- Readiness probe failures.
- Insufficient cluster resources.
- Scheduling constraints.

### Issue 2: Rollback Not Working

Check revision history:

```bash
kubectl rollout history deployment/nginx-demo
kubectl get replicasets
```

Possible causes:

- Required old ReplicaSet is no longer retained.
- Revision history was limited.
- The requested revision does not exist.

### Issue 3: Service Does Not Route Traffic to Canary Pods

Check labels:

```bash
kubectl get pods --show-labels
```

Check Service selector:

```bash
kubectl describe service nginx-canary-service
```

Check endpoints:

```bash
kubectl get endpointslices \
  -l kubernetes.io/service-name=nginx-canary-service
```

Possible causes:

- Incorrect Pod labels.
- Incorrect Service selector.
- Pods are not ready.
- Target port is incorrect.

### Issue 4: Blue-Green Traffic Switch Is Not Working

Check:

```bash
kubectl get service nginx-production -o yaml
kubectl get pods --show-labels
kubectl get endpointslices \
  -l kubernetes.io/service-name=nginx-production
```

Ensure that the Service selector matches the labels of the intended environment and that the selected Pods are ready.

---

## 12. Best Practices

1. Use Rolling Update as the default strategy for most stateless applications.
2. Configure readiness probes so traffic is sent only to ready Pods.
3. Set suitable `maxSurge` and `maxUnavailable` values.
4. Use startup probes for applications with slow initialization.
5. Use Canary deployments when gradual production exposure is important.
6. Use Blue-Green deployments when you need to validate an entire environment before switching traffic.
7. Keep old ReplicaSets available for a reasonable rollback window.
8. Use immutable image tags or image digests rather than relying on mutable tags such as `latest`.
9. Keep database migrations backward-compatible when old and new application versions may run simultaneously.
10. Monitor error rates, latency, resource usage, and application logs during deployments.
11. Use CI/CD tools such as Azure DevOps, GitHub Actions, or Argo CD to standardize releases.
12. Test rollback procedures before production incidents occur.

---

## 13. Common Interview Questions

### Q1. What is a Rolling Update in Kubernetes?

Rolling Update gradually replaces old Pods with new Pods while maintaining application availability where possible.

### Q2. What is the difference between Rolling Update and Recreate?

Rolling Update gradually replaces Pods. Recreate terminates the old Pods before creating the new ones, which can cause downtime.

### Q3. What is `maxSurge`?

It defines how many additional Pods can be created above the desired replica count during a rolling update.

### Q4. What is `maxUnavailable`?

It defines the maximum number of Pods that can be unavailable during a rolling update.

### Q5. What is a Kubernetes rollback?

Rollback restores a Deployment to a previous revision.

### Q6. How do you roll back a Deployment to revision 2?

```bash
kubectl rollout undo deployment/nginx-demo \
  --to-revision=2
```

### Q7. What is Canary Deployment?

Canary deployment introduces a new application version to a limited portion of production traffic before gradually expanding the rollout.

### Q8. Does Kubernetes Service support weighted traffic routing natively?

No. A standard Service selects matching endpoints but does not provide configurable percentage-based traffic splitting. Use a suitable ingress controller, Gateway API implementation, service mesh, or progressive delivery tool.

### Q9. What is Blue-Green Deployment?

Blue-Green maintains two application environments. Traffic is switched from the old environment to the new one after validation.

### Q10. How can you implement Blue-Green Deployment in Kubernetes?

Deploy two versions with different labels and use a Service selector or another traffic-routing mechanism to direct traffic to the active version.

### Q11. What is Revision History?

Revision History stores previous Deployment rollout configurations, allowing administrators to inspect and roll back to earlier revisions.

### Q12. What is `revisionHistoryLimit`?

It controls how many old ReplicaSets are retained by a Deployment for rollout history and rollback.

### Q13. Does scaling a Deployment create a new revision?

No. Scaling changes the replica count but does not change the Pod template, so it does not create a new Deployment revision.

### Q14. Can Rolling Update cause downtime?

It can, depending on readiness, replica availability, application behaviour, resource capacity, and configuration. Proper readiness probes and rollout settings help avoid downtime.

### Q15. How would you deploy a new version in production AKS with minimal risk?

A good approach is to use a controlled Rolling Update or Canary strategy, configure readiness and startup probes, monitor application metrics, validate the new version, and maintain a tested rollback procedure.

---

## 14. Official Documentation

- [Kubernetes — Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes — Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Kubernetes — Rollback Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
- [Argo Rollouts Documentation](https://argo-rollouts.readthedocs.io/en/stable/)
- [Kubernetes — Services](https://kubernetes.io/docs/concepts/services-networking/service/)

---

## Conclusion

Kubernetes deployment strategies help teams release application versions safely and reliably.

Remember:

- **Rolling Update:** Gradually replace old Pods with new Pods.
- **Recreate:** Stop old Pods before creating new Pods.
- **Rollback:** Return to a previous Deployment revision.
- **Canary:** Introduce a new version to a limited portion of production traffic.
- **Blue-Green:** Switch traffic between two independently deployed environments.
- **Revision History:** Inspect and recover previous Deployment configurations.

Understanding these strategies is essential for managing production Kubernetes workloads and designing reliable CI/CD pipelines in AKS.