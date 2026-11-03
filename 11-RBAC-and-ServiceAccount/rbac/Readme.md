````markdown
# Kubernetes RBAC - Service Account with Read-Only Pod Access

## Objective

Create a Kubernetes **ServiceAccount** that can **only read Pods** (`get`, `list`, `watch`) within a specific namespace. It **cannot create, update, delete, or modify** any resources.

---

# Architecture

```text
                    Kubernetes Cluster
                           │
                           │
                  ┌───────────────────┐
                  │ ServiceAccount    │
                  │ dev-app-sa        │
                  └─────────┬─────────┘
                            │
                     RoleBinding
                            │
                            ▼
                  ┌───────────────────┐
                  │ Role              │
                  │ pod-reader-role   │
                  └─────────┬─────────┘
                            │
                     Permissions
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │                  
      watch pods                        ❌ create pods
      list pods                         ❌ delete pods
      get pods                          ❌ update pods
```

---

# Namespace

```bash
kubectl create namespace service-account
```

Verify

```bash
kubectl get ns
```

---

# Step 1 - Create ServiceAccount

**serviceaccount.yaml**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-app-sa
  namespace: service-account
```

Apply

```bash
kubectl apply -f serviceaccount.yaml
```

Verify

```bash
kubectl get sa -n service-account
```

Expected

```
NAME         SECRETS   AGE
dev-app-sa   0         10s
```

---

# Step 2 - Create Role

This Role allows only:

- get
- list
- watch

for Pods.

**role.yaml**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: service-account

rules:
- apiGroups: [""]
  resources:
    - pods
  verbs:
    - get
    - list
    - watch
```

Apply

```bash
kubectl apply -f role.yaml
```

Verify

```bash
kubectl get role -n service-account
```

---

# Step 3 - Create RoleBinding

This binds the ServiceAccount to the Role.

**rolebinding.yaml**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: service-account

subjects:
- kind: ServiceAccount
  name: dev-app-sa
  namespace: service-account

roleRef:
  kind: Role
  name: pod-reader-role
  apiGroup: rbac.authorization.k8s.io
```

Apply

```bash
kubectl apply -f rolebinding.yaml
```

Verify

```bash
kubectl get rolebinding -n service-account
```

---

# Verify RBAC Permissions

## Can Read Pods

```bash
kubectl auth can-i get pods \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Expected

```
yes
```

---

## Can List Pods

```bash
kubectl auth can-i list pods \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Expected

```
yes
```

---

## Can Watch Pods

```bash
kubectl auth can-i watch pods \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Expected

```
yes
```

---

## Can Create Pods

```bash
kubectl auth can-i create pods \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Expected

```
no
```

---

## Can Delete Pods

```bash
kubectl auth can-i delete pods \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Expected

```
no
```

---

## Can Update Pods

```bash
kubectl auth can-i update pods \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Expected

```
no
```

---

## Can Patch Pods

```bash
kubectl auth can-i patch pods \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Expected

```
no
```

---

# Display All Effective Permissions

```bash
kubectl auth can-i --list \
--as=system:serviceaccount:service-account:dev-app-sa \
-n service-account
```

Sample Output

```
Resources        Non-Resource URLs   Resource Names   Verbs

pods             []                  []               get
pods             []                  []               list
pods             []                  []               watch
```

---

# Test by Creating a Token

Generate a ServiceAccount token.

```bash
kubectl create token dev-app-sa -n service-account
```

---

# Test Using the ServiceAccount

Create a kubeconfig using the generated token or use it from a Pod running with this ServiceAccount.

Try:

```bash
kubectl get pods
```

Works ✅

Try:

```bash
kubectl create deployment nginx \
--image=nginx
```

Fails ❌

```
Error from server (Forbidden)
```

---

# Resource Relationship

```text
ServiceAccount
      │
      ▼
RoleBinding
      │
      ▼
Role
      │
      ▼
Permissions

get
list
watch
```

---

# Difference Between Role and RoleBinding

## Role

Defines **what** permissions are allowed.

Example

```
Read Pods
Read Services
Read ConfigMaps
```

---

## RoleBinding

Defines **who** receives those permissions.

Example

```
ServiceAccount

or

Azure AD User

or

Azure AD Group
```

---

# If You Want to Give Access to an Azure User

Replace the ServiceAccount with a User.

```yaml
subjects:
- kind: User
  name: user@company.com
  apiGroup: rbac.authorization.k8s.io
```

Or preferably use an Azure AD Group.

```yaml
subjects:
- kind: Group
  name: <AAD-GROUP-OBJECT-ID>
  apiGroup: rbac.authorization.k8s.io
```

---

# Production Best Practices

- Use least privilege access.
- Prefer Groups over individual Users.
- Avoid using ClusterRole unless cluster-wide access is required.
- Use Role for namespace-scoped permissions.
- Grant only the required verbs.
- Never assign cluster-admin unless absolutely necessary.
- Audit RBAC permissions regularly.
- Use separate ServiceAccounts for different applications.

---

# Summary

| Component | Purpose |
|-----------|---------|
| Namespace | Logical isolation |
| ServiceAccount | Identity for Pods |
| Role | Defines allowed actions |
| RoleBinding | Assigns Role to ServiceAccount |
| RBAC | Controls authorization |
| `kubectl auth can-i` | Verifies permissions |

---

# Final Permission Matrix

| Resource | Get | List | Watch | Create | Update | Delete |
|----------|:---:|:----:|:-----:|:------:|:------:|:------:|
| Pods | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |


````

This README is interview-friendly, production-oriented, and documents the complete RBAC flow from ServiceAccount creation to permission verification.
