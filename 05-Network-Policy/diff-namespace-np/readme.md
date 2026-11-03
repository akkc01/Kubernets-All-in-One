# Kubernetes Network Policy with Multi-Namespace Communication

## 📌 Project Overview

This project demonstrates how to secure communication between applications running in different Kubernetes namespaces using **Deployments**, **Services**, and **Network Policies**.

In this setup:

* Created two namespaces:

  * `firefox-ns`
  * `nginx-ns`
* Deployed a **Firefox Deployment** in `firefox-ns`.
* Deployed an **Nginx Deployment** in `nginx-ns`.
* Exposed both applications using Kubernetes Services:

  * `firefox-service`
  * `nginx-service`
* Implemented **Network Policies** to control traffic between the namespaces and enforce secure communication.

---

## 🏗️ Architecture

```text id="vyj69q"
+------------------------+
| Namespace: firefox-ns  |
|------------------------|
| Firefox Deployment     |
| Firefox Service        |
+------------------------+
            |
            | Allowed
            ▼
+------------------------+
| Namespace: nginx-ns    |
|------------------------|
| Nginx Deployment       |
| Nginx Service          |
+------------------------+

Any other traffic ❌ Denied
```

---

## 📂 Resources Created

### Namespaces

* `firefox-ns`
* `nginx-ns`

### Deployments

* Firefox Deployment
* Nginx Deployment

### Services

* `firefox-service`
* `nginx-service`

### Network Policies

* Allow traffic from Firefox Pods to Nginx Pods.
* Restrict unauthorized ingress and egress traffic.

---

## 🚀 Deployment Steps

### Create Namespaces

```bash id="ic5r7i"
kubectl create namespace firefox-ns
kubectl create namespace nginx-ns
```

### Deploy Applications

```bash id="k7ztx4"
kubectl apply -f firefox-deployment.yaml
kubectl apply -f nginx-deployment.yaml
```

### Create Services

```bash id="9zc1ol"
kubectl apply -f firefox-service.yaml
kubectl apply -f nginx-service.yaml
```

### Apply Network Policies

```bash id="sn5h74"
kubectl apply -f firefox-networkpolicy.yaml
kubectl apply -f nginx-networkpolicy.yaml
```

---

## 🔒 Network Policy – Nginx Namespace

Allows traffic only from Firefox Pods running in the `firefox-ns` namespace.

```yaml id="l4s1n7"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-firefox-to-nginx
  namespace: nginx-ns
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: firefox-ns
      podSelector:
        matchLabels:
          app: firefox
```

---

## 🔒 Network Policy – Firefox Namespace

Restricts traffic in the `firefox-ns` namespace and allows only required communication.

```yaml id="4l55yv"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: firefox-policy
  namespace: firefox-ns
spec:
  podSelector:
    matchLabels:
      app: firefox
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: nginx-ns
      podSelector:
        matchLabels:
          app: nginx
```

---

## ✅ Connectivity Test

Verify communication from Firefox to Nginx:

```bash id="ob0g7u"
kubectl exec -it deployment/firefox -n firefox-ns -- \
curl http://nginx-service.nginx-ns.svc.cluster.local
```

Expected output:

```text id="o9h1m6"
Welcome to nginx!
```

Any Pod outside the allowed policies will not be able to communicate with the Nginx application.

---

## 📚 Concepts Covered

* Kubernetes Namespaces
* Deployments
* Services
* Cross-Namespace Communication
* DNS-Based Service Discovery
* Network Policies
* Ingress and Egress Rules
* Micro-Segmentation
* Zero Trust Networking

---

## 🎯 Learning Outcome

This project demonstrates how to use **Kubernetes Network Policies** to secure communication between applications deployed in different namespaces. By combining **Deployments**, **Services**, and **Network Policies**, we can implement fine-grained network security and ensure that only authorized workloads can communicate with each other.

You can also add screenshots of `kubectl get all -A`, `kubectl get netpol -A`, and the successful `curl` output in your GitHub repository to make the project portfolio-ready.
