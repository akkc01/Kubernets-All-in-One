# Kubernetes ServiceAccount (SA) and RBAC

## 1. Introduction

Kubernetes provides an authorization mechanism called **Role-Based Access Control (RBAC)** to control who can access Kubernetes API resources and what actions they can perform.

RBAC works with identities such as:

- Users
- Groups
- ServiceAccounts

This README explains how to create ServiceAccounts, Roles, ClusterRoles and their bindings.

## 2. What is a ServiceAccount?

A ServiceAccount (SA) is a Kubernetes identity used by applications and Pods to communicate with the Kubernetes API Server.

For example, suppose an application running inside a Pod needs to:

- List Pods.
- Read ConfigMaps.
- Get Deployments.
- Watch Kubernetes resources.

The application can use a ServiceAccount to authenticate with the Kubernetes API Server.

### Architecture

```
              Kubernetes Cluster
                     |
                     |
              +-------------+
              | Application |
              |     Pod     |
              +-------------+
                     |
                     |
              ServiceAccount
                     |
                     |
              Authentication
                     |
                     |
              Kubernetes API
                     |
                     |
                   RBAC
                     |
                     |
              Authorization
                     |
                     |
              API Resources
```

**Important:** A ServiceAccount provides an identity, not permissions. RBAC determines what that identity can do.

## 3. Create a Namespace

```
kubectl create namespace dev
```

Verify:

```
kubectl get namespaces
```

## 4. Create a ServiceAccount

Create `service-account.yaml`:

```
apiVersion: v1
kind: ServiceAccount

metadata:
  name: dev-sa
  namespace: dev
```

Apply:

```
kubectl apply -f service-account.yaml
```

Verify:

```
kubectl get serviceaccounts -n dev
```

Describe:

```
kubectl describe serviceaccount dev-sa -n dev
```

## 5. What is Kubernetes RBAC?

RBAC stands for Role-Based Access Control.

It controls which Kubernetes API operations an identity can perform.

For example:

| Permission | Description                |
| ---------- | -------------------------- |
| get        | Read a specific resource   |
| list       | List resources             |
| watch      | Watch resource changes     |
| create     | Create resources           |
| update     | Update resources           |
| patch      | Partially modify resources |
| delete     | Delete resources           |

RBAC has four major components:

1. Role
2. RoleBinding
3. ClusterRole
4. ClusterRoleBinding

## 6. What is a Role?

A Role defines permissions within a particular namespace.

For example, we can create a Role that allows a ServiceAccount to:

- Get Pods.
- List Pods.
- Watch Pods.
- Read ConfigMaps.

Create `role.yaml`:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:
  name: pod-reader
  namespace: dev

rules:
  - apiGroups: [""]
    resources:
      - pods
      - configmaps

    verbs:
      - get
      - list
      - watch
```

Apply:

```
kubectl apply -f role.yaml
```

Verify:

```
kubectl get roles -n dev
```

Describe:

```
kubectl describe role pod-reader -n dev
```

### Understanding Role fields

| Field     | Purpose              |
| --------- | -------------------- |
| apiGroups | Kubernetes API group |
| resources | Resources to access  |
| verbs     | Allowed operations   |
| namespace | Scope of the Role    |

For core resources such as Pods, Services and ConfigMaps, use an empty API group: `""`.

## 7. What is a RoleBinding?

A RoleBinding connects a Role with an identity such as a ServiceAccount.

In simple terms:

- Role defines permissions.
- ServiceAccount defines identity.
- RoleBinding connects the identity to the permissions.

Create `rolebinding.yaml`:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding

metadata:
  name: pod-reader-binding
  namespace: dev

subjects:
  - kind: ServiceAccount
    name: dev-sa
    namespace: dev

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

Apply:

```
kubectl apply -f rolebinding.yaml
```

Verify:

```
kubectl get rolebindings -n dev
```

### Architecture

```
ServiceAccount: dev-sa
        |
        |
        v
RoleBinding: pod-reader-binding
        |
        |
        v
Role: pod-reader
        |
        |
        v
Permissions:
  - get pods
  - list pods
  - watch pods
  - get configmaps
  - list configmaps
  - watch configmaps
```

## 8. Test ServiceAccount Permissions

Check whether the ServiceAccount can list Pods:

```
kubectl auth can-i list pods \
  --as=system:serviceaccount:dev:dev-sa \
  -n dev
```

Expected output:

```
yes
```

Check whether it can delete Pods:

```
kubectl auth can-i delete pods \
  --as=system:serviceaccount:dev:dev-sa \
  -n dev
```

Expected output:

```
no
```

Check ConfigMap permissions:

```
kubectl auth can-i get configmaps \
  --as=system:serviceaccount:dev:dev-sa \
  -n dev
```

Expected output:

```
yes
```

**Note:** `kubectl auth can-i --as` impersonates the ServiceAccount. Your own Kubernetes identity must have permission to impersonate that ServiceAccount for this test.

## 9. What is a ClusterRole?

A ClusterRole defines permissions at the cluster level.

Unlike a Role, a ClusterRole is not restricted to one namespace.

It can define permissions for:

- Cluster-scoped resources such as Nodes and PersistentVolumes.
- Namespaced resources such as Pods and Services.
- Non-resource URLs such as `/healthz`.

Create `clusterrole.yaml`:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole

metadata:
  name: cluster-pod-reader

rules:
  - apiGroups: [""]
    resources:
      - pods
      - nodes

    verbs:
      - get
      - list
      - watch
```

Apply:

```
kubectl apply -f clusterrole.yaml
```

Verify:

```
kubectl get clusterroles
```

## 10. What is a ClusterRoleBinding?

A ClusterRoleBinding grants the permissions defined in a ClusterRole across the entire cluster.

Create `clusterrolebinding.yaml`:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding

metadata:
  name: cluster-pod-reader-binding

subjects:
  - kind: ServiceAccount
    name: dev-sa
    namespace: dev

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-pod-reader
```

Apply:

```
kubectl apply -f clusterrolebinding.yaml
```

Verify:

```
kubectl get clusterrolebindings
```

Test:

```
kubectl auth can-i list nodes \
  --as=system:serviceaccount:dev:dev-sa
```

Expected output:

```
yes
```

## 11. Role vs ClusterRole

| Feature                    | Role                                        | ClusterRole               |
| -------------------------- | ------------------------------------------- | ------------------------- |
| Scope                      | Namespace                                   | Cluster-wide definition   |
| Namespaced resources       | Yes                                         | Yes                       |
| Cluster-scoped resources   | No                                          | Yes                       |
| Reusable across namespaces | Can be referenced through separate bindings | Yes                       |
| Example                    | Read Pods in dev                            | Read Nodes across cluster |

## 12. RoleBinding vs ClusterRoleBinding

| Feature                   | RoleBinding                       | ClusterRoleBinding                        |
| ------------------------- | --------------------------------- | ----------------------------------------- |
| Permission scope          | One namespace                     | Entire cluster                            |
| Can reference Role        | Yes                               | No                                        |
| Can reference ClusterRole | Yes                               | Yes                                       |
| Typical use               | Developer access to dev namespace | Cluster monitoring or cluster-wide access |

**Important:** A RoleBinding can reference a ClusterRole but grants its permissions only within the RoleBinding's namespace. A ClusterRoleBinding grants the referenced ClusterRole permissions cluster-wide.

## 13. Use ServiceAccount in a Deployment

A Deployment can assign a ServiceAccount to its Pods using `serviceAccountName`.

Create `deployment.yaml`:

```
apiVersion: apps/v1
kind: Deployment

metadata:
  name: nginx-deployment
  namespace: dev

spec:
  replicas: 2

  selector:
    matchLabels:
      app: nginx

  template:
    metadata:
      labels:
        app: nginx

    spec:
      serviceAccountName: dev-sa

      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
```

Apply:

```
kubectl apply -f deployment.yaml
```

Verify:

```
kubectl get pods -n dev
```

Check which ServiceAccount the Pod uses:

```
kubectl get pod <POD_NAME> -n dev \
  -o jsonpath='{.spec.serviceAccountName}'
```

Expected:

```
dev-sa
```

**Note:** NGINX does not automatically use Kubernetes API permissions. An application needs a Kubernetes client library or API calls to use the ServiceAccount identity.

## 14. Default ServiceAccount

Every Kubernetes namespace automatically has a ServiceAccount named `default`.

Check:

```
kubectl get serviceaccounts -n dev
```

If you do not specify `serviceAccountName` in a Pod specification, Kubernetes normally assigns the namespace's `default` ServiceAccount.

Production recommendation:

- Create dedicated ServiceAccounts.
- Avoid using the default ServiceAccount for applications.
- Grant only the required permissions.

## 15. ServiceAccount Token

ServiceAccount tokens are used to authenticate workloads with the Kubernetes API Server.

Modern Kubernetes versions use projected, short-lived ServiceAccount tokens by default when a Pod needs an API token.

Check token projection in a Pod:

```
kubectl describe pod <POD_NAME> -n dev
```

You may see a projected volume mounted at:

```
/var/run/secrets/kubernetes.io/serviceaccount
```

To prevent automatic token mounting when the application does not need Kubernetes API access:

```
spec:
  automountServiceAccountToken: false
```

This can be configured on a Pod or ServiceAccount.

## 16. Complete Hands-on Project

Create these four files:

```
kubernetes-rbac/
│
├── namespace.yaml
├── service-account.yaml
├── role.yaml
├── rolebinding.yaml
└── deployment.yaml
```

Apply them:

```
kubectl apply -f namespace.yaml
kubectl apply -f service-account.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
kubectl apply -f deployment.yaml
```

Verify all resources:

```
kubectl get all -n dev
kubectl get sa,role,rolebinding -n dev
```

Test permissions:

```
kubectl auth can-i list pods \
  --as=system:serviceaccount:dev:dev-sa \
  -n dev

kubectl auth can-i delete pods \
  --as=system:serviceaccount:dev:dev-sa \
  -n dev
```

Expected:

```
yes
no
```

## 17. Troubleshooting

### Error: Forbidden

Example:

```
Error from server (Forbidden):
pods is forbidden:
User "system:serviceaccount:dev:dev-sa"
cannot list resource "pods" in API group ""
```

Possible reasons:

- Role does not include the required resource.
- Role does not include the required verb.
- RoleBinding references the wrong ServiceAccount.
- RoleBinding references the wrong Role.
- Namespace mismatch.

Useful commands:

```
kubectl get sa -n dev
kubectl get role -n dev
kubectl get rolebinding -n dev
```

Inspect RoleBinding:

```
kubectl describe rolebinding pod-reader-binding -n dev
```

Check authorization:

```
kubectl auth can-i list pods \
  --as=system:serviceaccount:dev:dev-sa \
  -n dev
```

## 18. Security Best Practices

1. Follow the principle of least privilege.
2. Avoid granting `cluster-admin` unnecessarily.
3. Use separate ServiceAccounts for different applications.
4. Avoid wildcard resources and verbs unless absolutely necessary.
5. Restrict access to ServiceAccounts using RBAC.
6. Disable automatic token mounting when not required.
7. Use short-lived projected tokens.
8. Review RoleBindings and ClusterRoleBindings regularly.
9. Separate development, QA and production access.
10. Never commit ServiceAccount tokens to GitHub.

## 19. Interview Questions

**Q1. What is a Kubernetes ServiceAccount?**

A Kubernetes identity used by Pods and applications to authenticate with the Kubernetes API Server.

**Q2. Does a ServiceAccount automatically have permissions to list Pods?**

No. Permissions must be granted through RBAC.

**Q3. What is the difference between Role and ClusterRole?**

Role defines namespace-scoped permissions, while ClusterRole defines reusable permissions that can cover namespaced or cluster-scoped resources.

**Q4. What is the difference between RoleBinding and ClusterRoleBinding?**

RoleBinding grants permissions within one namespace. ClusterRoleBinding grants permissions cluster-wide.

**Q5. Can a RoleBinding reference a ClusterRole?**

Yes. It grants the ClusterRole's permissions only within the RoleBinding's namespace.

**Q6. Can one ServiceAccount be used by multiple Pods?**

Yes. Multiple Pods in the same namespace can use the same ServiceAccount.

**Q7. Can one ServiceAccount be used across multiple namespaces?**

No. ServiceAccounts are namespace-scoped. You must create a separate ServiceAccount in each namespace.

**Q8. What happens if no ServiceAccount is specified?**

Kubernetes normally assigns the namespace's default ServiceAccount.

**Q9. What does `kubectl auth can-i` do?**

It checks whether an identity is authorized to perform a particular Kubernetes API operation.

**Q10. How do you provide read-only access to Pods?**

Create a Role with `get`, `list` and `watch` verbs for Pods, then bind it to the required ServiceAccount or user.

---

## 20. Official Documentation

- [Kubernetes Service Accounts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [Kubernetes RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
- [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

**Technology Stack:** Kubernetes | AKS | ServiceAccount | RBAC | Role | RoleBinding | ClusterRole | ClusterRoleBinding

Recommended repository structure:

```
kubernetes-security/
├── README.md
├── service-account.yaml
├── role.yaml
├── rolebinding.yaml
├── clusterrole.yaml
└── clusterrolebinding.yaml
```

This gives you a practical Kubernetes RBAC project that you can demonstrate during DevOps and AKS interviews.