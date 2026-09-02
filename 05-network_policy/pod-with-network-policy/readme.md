# Kubernetes Network Policy Demo

## 📌 Project Overview

This project demonstrates how to use **Kubernetes Network Policies** to control communication between Pods within the same namespace.

In this setup:

* Created an **Nginx Pod** that serves the application.
* Created a **Firefox Pod** to test connectivity.
* Created a namespace named **nginx-ns**.
* Applied a **Network Policy** that allows only the Firefox Pod to access the Nginx Pod while restricting access from all other Pods.

---

## 🏗️ Architecture

```text id="g70f9s"
Namespace: nginx-ns

├── firefox-pod  ───────────► nginx-pod ✅ Allowed
└── other-pods   ───────────► nginx-pod ❌ Denied
```

---

## 📂 Resources Created

* Namespace: `nginx-ns`
* Nginx Pod
* Firefox Pod
* Network Policy

---

## 🚀 Deployment Steps

### Create Namespace

```bash id="4ddccq"
kubectl create namespace nginx-ns
```

### Deploy Nginx Pod

```bash id="6w0vdm"
kubectl apply -f nginx.yaml -n nginx-ns
```

### Deploy Firefox Pod

```bash id="mznr97"
kubectl apply -f firefox.yaml -n nginx-ns
```

### Apply Network Policy

```bash id="ef8yyh"
kubectl apply -f network-policy.yaml -n nginx-ns
```

---

## 🔒 Network Policy

```yaml id="3b2u5h"
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
    - podSelector:
        matchLabels:
          app: firefox
```

---

## ✅ Verification

Verify that the Firefox Pod can access the Nginx Pod:

```bash id="g8t4pw"
kubectl exec -it firefox -n nginx-ns -- curl nginx
```

Expected output:

```text id="s14vhx"
Welcome to nginx!
```

Any other Pod in the `nginx-ns` namespace attempting to access the Nginx Pod will be denied.

---

## 📚 Concepts Covered

* Kubernetes Namespaces
* Pod-to-Pod Communication
* Network Policies
* Ingress Rules
* Pod Selectors
* Kubernetes Network Security
* Micro-Segmentation

---

## 🎯 Learning Outcome

This project demonstrates how Kubernetes Network Policies can be used to implement **Zero Trust networking** and **micro-segmentation** by allowing communication only from authorized Pods while denying all other traffic.

This is a simple hands-on project to understand how **NetworkPolicy acts as a firewall for Pods in Kubernetes**.
