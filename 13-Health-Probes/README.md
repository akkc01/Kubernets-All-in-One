# Kubernetes Probes — Liveness, Readiness, and Startup Probes

## Table of Contents

1. [Introduction](#1-introduction)
2. [What Are Kubernetes Probes?](#2-what-are-kubernetes-probes)
3. [Liveness Probe](#3-liveness-probe)
4. [Readiness Probe](#4-readiness-probe)
5. [Startup Probe](#5-startup-probe)
6. [Liveness vs Readiness vs Startup](#6-liveness-vs-readiness-vs-startup)
7. [Probe Handlers](#7-probe-handlers)
8. [Probe Configuration Parameters](#8-probe-configuration-parameters)
9. [Complete Deployment Example](#9-complete-deployment-example)
10. [Hands-on Lab](#10-hands-on-lab)
11. [Troubleshooting](#11-troubleshooting)
12. [Best Practices](#12-best-practices)
13. [Common Interview Questions](#13-common-interview-questions)
14. [Official Documentation](#14-official-documentation)

---

## 1. Introduction

In Kubernetes, running a container does not necessarily mean that the application inside it is healthy or ready to serve traffic.

For example:

- A container may be running, but the application could be frozen.
- An application may need 60 seconds to initialize.
- A web application may be running but not ready to accept requests.
- An application may become unhealthy after deployment.

Kubernetes provides **Probes** to monitor the health and availability of containers.

There are three primary types of probes:

| Probe | Purpose |
|---|---|
| Liveness Probe | Determines whether a container needs to be restarted. |
| Readiness Probe | Determines whether a container can receive traffic. |
| Startup Probe | Determines whether an application has completed its startup process. |

### Why Do We Need Probes?

Without probes, Kubernetes primarily knows whether a container process is running. It cannot reliably determine whether the application is functioning correctly.

Probes help Kubernetes manage application health automatically.

---

## 2. What Are Kubernetes Probes?

A Kubernetes probe is a periodic diagnostic performed by the kubelet to check the health of a container.

Based on the probe result, Kubernetes takes different actions.

```text
                 Kubernetes Pod
                       |
                       |
                Container Running
                       |
                       |
                 Probe Checks
                       |
          +------------+------------+
          |            |            |
          v            v            v
       Liveness     Readiness     Startup
          |            |            |
          v            v            v
      Restart       Control      Verify App
      Container     Traffic       Startup
```

### Probe Execution

The kubelet performs configured health checks against containers.

Probe results can be:

- **Success:** The diagnostic succeeded.
- **Failure:** The diagnostic failed.
- **Unknown:** The diagnostic could not be completed, so no action is taken.

---

## 3. Liveness Probe

### What is a Liveness Probe?

A Liveness Probe checks whether an application is still functioning correctly.

If the liveness probe repeatedly fails, Kubernetes restarts the affected container.

**Example scenario:**

Imagine an application running inside a Kubernetes Pod.

- The application starts successfully.
- After some time, the application becomes unresponsive.
- The container is still running.
- Kubernetes detects repeated liveness probe failures.
- Kubernetes restarts the container.

### Liveness Probe YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-demo
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80

      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 10
        periodSeconds: 5
        timeoutSeconds: 2
        failureThreshold: 3
```

### Explanation

| Parameter | Description |
|---|---|
| `httpGet` | Performs an HTTP request against the container. |
| `path` | HTTP endpoint to check. |
| `port` | Container port used for the health check. |
| `initialDelaySeconds` | Time to wait before starting the first probe. |
| `periodSeconds` | Interval between consecutive probes. |
| `timeoutSeconds` | Maximum time allowed for a probe response. |
| `failureThreshold` | Number of consecutive failures required before the probe is considered failed. |

### What Happens When Liveness Fails?

```text
Application Running
        |
        v
Liveness Check
        |
        v
Probe Failed
        |
        v
Repeated Failures
        |
        v
Container Restart
        |
        v
Application Starts Again
```

**Important:** A failed liveness probe does not directly restart the Pod object. Kubelet restarts the affected container according to its restart policy.

---

## 4. Readiness Probe

### What is a Readiness Probe?

A Readiness Probe checks whether an application is ready to accept incoming traffic.

If the readiness probe fails, Kubernetes marks the container as not ready.

The Pod is then excluded from the ready endpoints of Services that select it.

**Example scenario:**

Imagine a web application deployed with three replicas.

- All three Pods are running.
- One Pod is still loading application data.
- Its readiness probe fails.
- Kubernetes stops routing Service traffic to that Pod.
- The other two ready Pods continue serving requests.

### Readiness Probe YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-demo
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80

      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 5
        timeoutSeconds: 2
        failureThreshold: 3
        successThreshold: 1
```

### How Readiness Works

```text
             Application Running
                      |
                      v
                Readiness Check
                      |
             +--------+--------+
             |                 |
             v                 v
           Success           Failure
             |                 |
             v                 v
        Pod Ready          Pod Not Ready
             |                 |
             v                 v
       Service Routes     Removed from
       Traffic            Ready Endpoints
```

### Important Points

- A failed readiness probe does not restart the container.
- Kubernetes removes the Pod from ready Service endpoints.
- The probe continues running.
- Once the probe succeeds, the Pod can become ready again.
- Readiness is particularly useful during application initialization and temporary overload.

---

## 5. Startup Probe

### What is a Startup Probe?

A Startup Probe checks whether an application has successfully completed its startup process.

It is particularly useful for applications that require significant initialization time.

**Example scenario:**

Consider a Java application that requires 90 seconds to start.

If a liveness probe begins checking too early, Kubernetes might repeatedly restart the container before the application has finished initializing.

A Startup Probe prevents this situation.

### Startup Probe YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-demo
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80

      startupProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 30
        timeoutSeconds: 2
```

### How Startup Probe Works

```text
              Container Starts
                     |
                     v
               Startup Probe
                     |
             +-------+-------+
             |               |
             v               v
          Success          Failure
             |               |
             v               v
      Startup Complete   Retry Probe
             |               |
             v               v
      Liveness and       Threshold
      Readiness Start     Reached?
             |               |
             v               v
       Normal Health     Container
         Monitoring       Restart
```

### Important Points

- Startup Probe protects slow-starting applications.
- Liveness and readiness probes do not run until the startup probe succeeds.
- If the startup probe reaches its failure threshold, kubelet restarts the container.
- After startup succeeds, normal liveness and readiness monitoring begins.

### Example Startup Window

With:

```yaml
periodSeconds: 5
failureThreshold: 30
```

The approximate startup failure window is:

`5 × 30 = 150 seconds`

This gives the application roughly 150 seconds of probe failures before Kubernetes restarts the container. Actual timing can vary due to scheduling and probe execution time.

---

## 6. Liveness vs Readiness vs Startup

| Feature | Liveness | Readiness | Startup |
|---|---|---|---|
| Purpose | Checks application health | Checks traffic readiness | Checks startup completion |
| Failure action | Restarts container | Marks container not ready | Restarts container after threshold |
| Removes traffic | Not directly | Yes | Pod remains unready until startup succeeds |
| Used for | Detecting stuck applications | Controlling traffic | Slow initialization |
| Runs during startup | After startup probe succeeds, if configured | After startup probe succeeds, if configured | Yes |

### Real-World Example

Consider a microservices application running in AKS.

- **Startup Probe:** Waits until the application finishes loading configuration and initializing.
- **Liveness Probe:** Detects whether the application has become stuck.
- **Readiness Probe:** Ensures that only application instances ready to process requests receive traffic.

All three probes can be configured on the same container.

---

## 7. Probe Handlers

Kubernetes supports four main probe mechanisms.

### 7.1 HTTP GET

Kubernetes sends an HTTP GET request to a specified endpoint.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
    scheme: HTTP
```

**Use case:** Web applications and REST APIs.

A successful HTTP status code in the range 200–399 indicates success.

### 7.2 TCP Socket

Kubernetes attempts to establish a TCP connection to the specified port.

```yaml
readinessProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

**Use case:** Applications that expose a TCP port but do not provide an HTTP health endpoint.

A successful TCP connection indicates success. It does not necessarily prove that the application can process requests correctly.

### 7.3 Exec Command

Kubernetes executes a command inside the container.

```yaml
livenessProbe:
  exec:
    command:
      - cat
      - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 10
```

**Use case:** Applications that expose a local health status through a file or command.

- Exit code `0`: Success.
- Non-zero exit code: Failure.

### 7.4 gRPC Probe

Kubernetes can check the health of applications that implement the gRPC Health Checking Protocol.

```yaml
readinessProbe:
  grpc:
    port: 50051
    service: my-service
  initialDelaySeconds: 5
  periodSeconds: 10
```

**Use case:** gRPC-based microservices.

The application must implement the gRPC health checking protocol. The probe does not support TLS or authentication parameters.

---

## 8. Probe Configuration Parameters

These are the main parameters used to configure Kubernetes probes.

| Parameter | Default | Description |
|---|---:|---|
| `initialDelaySeconds` | 0 | Seconds to wait before the first probe. |
| `periodSeconds` | 10 | Seconds between probe executions. |
| `timeoutSeconds` | 1 | Maximum duration of a probe. |
| `successThreshold` | 1 | Consecutive successes required to recover from failure. |
| `failureThreshold` | 3 | Consecutive failures required to mark the probe failed. |
| `terminationGracePeriodSeconds` | Inherited from Pod | Grace period before forcefully terminating the container after a liveness or startup failure. |

### Important Configuration Rules

- `periodSeconds`, `timeoutSeconds`, and `failureThreshold` must be greater than zero.
- `initialDelaySeconds` must be zero or greater.
- For liveness and startup probes, `successThreshold` must be `1`.
- For readiness probes, `successThreshold` can be greater than `1`.
- `terminationGracePeriodSeconds` can override the Pod-level termination grace period for liveness and startup probe failures.

### Example

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
  terminationGracePeriodSeconds: 30
```

---

## 9. Complete Deployment Example

This example configures all three probes on an Nginx container.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-probes
  namespace: default
spec:
  replicas: 3

  selector:
    matchLabels:
      app: nginx-probes

  template:
    metadata:
      labels:
        app: nginx-probes

    spec:
      containers:
        - name: nginx
          image: nginx:1.27

          ports:
            - containerPort: 80

          startupProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 5
            failureThreshold: 30

          livenessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 10
            timeoutSeconds: 2
            failureThreshold: 3

          readinessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 5
            timeoutSeconds: 2
            failureThreshold: 3
```

Apply the manifest:

```bash
kubectl apply -f nginx-probes.yaml
```

Check Deployment:

```bash
kubectl get deployment
```

Check Pods:

```bash
kubectl get pods -o wide
```

Check detailed probe information:

```bash
kubectl describe pod <pod-name>
```

---

## 10. Hands-on Lab

### Lab 1: Create a Pod with a Liveness Probe

Create a file named `liveness-pod.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-lab
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80

      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 3
```

Apply:

```bash
kubectl apply -f liveness-pod.yaml
```

Verify:

```bash
kubectl get pods
kubectl describe pod liveness-lab
```

### Lab 2: Test Readiness Probe Failure

Create a Pod with an endpoint that does not exist.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-lab
  labels:
    app: readiness-lab
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80

      readinessProbe:
        httpGet:
          path: /health
          port: 80
        periodSeconds: 5
        failureThreshold: 2
```

Apply:

```bash
kubectl apply -f readiness-pod.yaml
```

Check Pod status:

```bash
kubectl get pods
```

Expected result:

```text
NAME            READY   STATUS
readiness-lab   0/1     Running
```

The container is running, but the Pod is not ready because `/health` does not exist in the default Nginx configuration.

Check events:

```bash
kubectl describe pod readiness-lab
```

### Lab 3: Test Startup Probe

Create a Pod with a startup probe.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-lab
spec:
  containers:
    - name: nginx
      image: nginx:latest

      startupProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 30

      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 10
        failureThreshold: 3
```

Apply:

```bash
kubectl apply -f startup-pod.yaml
```

Verify:

```bash
kubectl get pods
kubectl describe pod startup-lab
```

### Lab 4: Create a Service and Verify Readiness

Create a Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: readiness-service
spec:
  selector:
    app: readiness-lab
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

Apply:

```bash
kubectl apply -f readiness-service.yaml
```

Check EndpointSlices:

```bash
kubectl get endpointslices \
  -l kubernetes.io/service-name=readiness-service
```

Because the Pod is not ready, it should not appear as a ready endpoint.

Fix the readiness probe path to `/` and apply the updated manifest:

```bash
kubectl apply -f readiness-pod.yaml
```

Check again:

```bash
kubectl get pods
kubectl get endpointslices \
  -l kubernetes.io/service-name=readiness-service
```

The Pod should become ready and appear as a ready endpoint.

---

## 11. Troubleshooting

### Issue 1: Pod Running but Not Ready

Check:

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Possible causes:

- Incorrect HTTP path.
- Incorrect container port.
- Application is still initializing.
- Health endpoint returns an unsuccessful HTTP status code.

### Issue 2: Container Restarting Frequently

Check:

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

Possible causes:

- Liveness probe configured too aggressively.
- Application startup takes longer than expected.
- Health endpoint is timing out.
- Application is stuck or crashing.

### Issue 3: Readiness Probe Failing

Check:

```bash
kubectl describe pod <pod-name>
```

Verify:

- Correct health endpoint.
- Correct port.
- Application is listening on the expected interface.
- Application initialization has completed.

### Issue 4: Startup Probe Failure

Check:

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

Possible causes:

- Startup threshold is too low.
- Application takes longer to initialize.
- Health endpoint is unavailable during startup.

---

## 12. Best Practices

1. **Use all three probes where appropriate:** Configure startup, liveness, and readiness probes based on the application's lifecycle.
2. **Avoid aggressive liveness checks:** Give applications sufficient time to recover from temporary delays.
3. **Use startup probes for slow applications:** Especially useful for Java, .NET, and other applications with longer initialization times.
4. **Keep readiness checks meaningful:** Check whether the application can actually serve requests.
5. **Avoid dependency-heavy liveness checks:** Do not restart an application merely because an external database or API is temporarily unavailable.
6. **Use dedicated health endpoints:** Prefer endpoints such as `/health`, `/ready`, and `/startup`.
7. **Set appropriate timeouts:** Account for expected application response times.
8. **Test probes before production:** Validate thresholds and failure behaviour in a non-production environment.
9. **Monitor probe failures:** Use Kubernetes events, container restart counts, and monitoring dashboards.

---

## 13. Common Interview Questions

### Q1. What are Kubernetes probes?

Kubernetes probes are health checks performed by kubelet to determine whether containers are healthy, ready to serve traffic, or have completed startup.

### Q2. What is the difference between Liveness and Readiness?

Liveness determines whether a container should be restarted. Readiness determines whether a Pod should receive Service traffic.

### Q3. What happens when a Liveness Probe fails?

After the configured consecutive failure threshold is reached, kubelet restarts the container.

### Q4. Does a Readiness Probe failure restart a container?

No. It marks the container as not ready, and the Pod is removed from ready Service endpoints.

### Q5. Why do we need a Startup Probe?

It protects applications with slow startup times from being restarted by liveness checks before initialization completes.

### Q6. Can we configure all three probes in one container?

Yes. They can be configured together. When a startup probe is configured, liveness and readiness probes are held back until startup succeeds.

### Q7. What happens if a Readiness Probe fails temporarily?

The Pod becomes not ready and is excluded from ready Service endpoints. Once the probe succeeds again, it can receive traffic.

### Q8. What is the difference between a TCP and HTTP probe?

A TCP probe checks whether a connection can be established to a port. An HTTP probe checks an HTTP endpoint and its response status.

### Q9. What is `failureThreshold`?

It specifies how many consecutive failures are required before Kubernetes considers a probe failed.

### Q10. How do you troubleshoot a failing probe?

Use:

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

Check the endpoint, port, response time, application logs, and probe configuration.

### Q11. Can a Pod be Running but not Ready?

Yes. Running describes the container's execution state, while Ready indicates whether the Pod is prepared to receive traffic.

### Q12. Does a Startup Probe replace a Liveness Probe?

No. Startup protects the initialization phase. Liveness continues monitoring the application after startup succeeds.

### Q13. What is `terminationGracePeriodSeconds` in a probe?

It specifies how long kubelet waits for a container to terminate gracefully after a liveness or startup probe failure before forcefully terminating it.

### Q14. Should a liveness probe check database connectivity?

Generally, no. A temporary database outage should not cause every application instance to restart. Use readiness checks for dependencies that determine whether the application can serve traffic, and design health checks carefully.

### Q15. How do probes help in production AKS clusters?

They improve application availability by restarting unhealthy containers, preventing traffic from reaching unready Pods, and allowing slow-starting applications to initialize safely.

---

## 14. Official Documentation

- [Kubernetes — Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Kubernetes — Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Kubernetes — Services](https://kubernetes.io/docs/concepts/services-networking/service/)

---

## Conclusion

Kubernetes Probes are essential for maintaining application health and availability.

Remember:

- **Liveness:** Should Kubernetes restart this container?
- **Readiness:** Should this Pod receive traffic?
- **Startup:** Has this application finished starting?

Understanding these three probes is important for managing reliable workloads in Kubernetes, especially in production environments such as Azure Kubernetes Service (AKS).