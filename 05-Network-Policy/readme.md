A **NetworkPolicy** in Kubernetes is a resource used to **control network traffic between Pods** and between Pods and external endpoints.

By default, Kubernetes allows **all Pods to communicate with each other**. Network Policies act like a **firewall for Pods**, allowing you to define which traffic is permitted and which is denied.

### Why NetworkPolicy?

* Improve security by restricting unnecessary communication.
* Implement Zero Trust networking.
* Isolate applications and environments.
* Control ingress (incoming) and egress (outgoing) traffic.

### How it works

A NetworkPolicy selects Pods using labels and then defines rules for:

1. **Ingress** → Traffic coming into the Pod.
2. **Egress** → Traffic leaving the Pod.

---

### Example Architecture

```text
frontend Pod  --->  backend Pod ---> database Pod
```

Suppose:

* Frontend should access Backend.
* Backend should access Database.
* Frontend should NOT access Database directly.

Network Policies can enforce this communication pattern.

---

### Example 1: Allow only Frontend to access Backend

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: firefox
```

**Meaning:**

* Policy applies to Pods with label `app=backend`.
* Only Pods with label `app=firefox` in namespace `frontend` can connect.
* All other ingress traffic is denied.

---

### Example 2: Default Deny All Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

**Meaning:**

* Applies to all Pods in the namespace.
* Blocks all incoming traffic.

---

### Example 3: Default Deny All Egress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
```

**Meaning:**

* Blocks all outgoing traffic from Pods.

---

### Important Concepts

| Component         | Purpose                            |
| ----------------- | ---------------------------------- |
| podSelector       | Selects Pods the policy applies to |
| namespaceSelector | Selects namespaces                 |
| ingress           | Incoming traffic rules             |
| egress            | Outgoing traffic rules             |
| policyTypes       | Ingress, Egress, or both           |

---

### Traffic Flow Example

```text
Namespace: frontend
└── Firefox Pod

Namespace: backend
└── Nginx Pod

Policy:
Allow Firefox -> Nginx

Result:
✓ Firefox → Nginx
✗ Any other Pod → Nginx
```

---

### Prerequisite

Network Policies work only if your CNI plugin supports them, such as:

* Calico
* Cilium
* Antrea
* Azure CNI

---

### Interview Definition

**NetworkPolicy is a Kubernetes resource that controls ingress and egress traffic for Pods using label selectors, enabling micro-segmentation and network security within a Kubernetes cluster.**
