# Azure Workload Identity with AKS and Azure Key Vault

This guide explains how to configure **Azure Workload Identity** in AKS so that a Kubernetes workload can securely access **Azure Key Vault** without storing Azure credentials such as client secrets inside Kubernetes.

---

## Architecture

```text
                         Azure
                          │
              ┌───────────┴───────────┐
              │                       │
           AKS Cluster          Azure Key Vault
              │                       │
              │                       │
       OIDC Issuer Enabled            │
              │                       │
              ▼                       │
      Kubernetes ServiceAccount       │
          akkc-pod-sa                 │
              │                       │
              │ Federated Identity    │
              │ Credential            │
              ▼                       │
       Microsoft Entra ID             │
              │                       │
              ▼                       │
     User-Assigned Managed Identity   │
        aks-workload-identity         │
              │                       │
              │ Key Vault Secrets User│
              └───────────────────────┘
                          │
                          ▼
                    Read Secrets
```

---

# 1. Enable Workload Identity on AKS

Go to:

**Azure Portal → AKS → Your AKS Cluster → Properties**

Check the following:

* **OIDC issuer** → Enabled
* **Workload Identity** → Enabled

If Workload Identity is disabled:

**AKS → Settings → Authentication**

Enable:

**Workload identity**

> Azure Workload Identity uses the AKS OIDC issuer to establish trust between a Kubernetes ServiceAccount and an Azure identity.

---

# 2. Create a User-Assigned Managed Identity

Go to:

**Azure Portal → Managed Identities → Create**

Fill in:

| Setting        | Value                   |
| -------------- | ----------------------- |
| Subscription   | `<your-subscription>`   |
| Resource Group | `<your-resource-group>` |
| Region         | `<your-region>`         |
| Name           | `aks-workload-identity` |

Then:

**Review + create → Create**

After creation, open the managed identity and note its:

**Client ID**

Example:

```text
95251e3e-a73e-42c9-b84a-d3c1b85e6fc0
```

You will use this Client ID in the Kubernetes ServiceAccount.

---

# 3. Create Federated Identity Credential

Open:

**Azure Portal → Managed Identities → aks-workload-identity**

Then:

**Federated credentials → + Add credential**

Select:

```text
Scenario:
Kubernetes accessing Azure resources
```

Configure:

| Setting            | Value                        |
| ------------------ | ---------------------------- |
| Cluster issuer URL | `<AKS OIDC issuer URL>`      |
| Namespace          | `akkc`                       |
| Service account    | `akkc-pod-sa`                |
| Name               | `aks-federated-credential`   |
| Audience           | `api://AzureADTokenExchange` |

Click:

**Add**

This establishes the trust relationship:

```text
Kubernetes ServiceAccount
          │
          │ OIDC Token
          ▼
   Microsoft Entra ID
          │
          ▼
User-Assigned Managed Identity
```

The important point is that Azure trusts tokens issued for the specific Kubernetes ServiceAccount.

---

# 4. Assign Azure RBAC Permissions

Suppose the application needs to read secrets from:

**Azure Key Vault**

Go to:

**Key Vault → Access control (IAM) → Add role assignment**

Select:

```text
Role:
Key Vault Secrets User
```

Then:

```text
Assign access to:
Managed identity
```

Select:

```text
aks-workload-identity
```

Finally:

**Review + assign**

The permission flow is now:

```text
Azure Workload Identity
          │
          ▼
User-Assigned Managed Identity
          │
          ▼
Key Vault Secrets User
          │
          ▼
     Azure Key Vault
          │
          ▼
    Read Secrets
```

> Make sure the RBAC model and Key Vault configuration support Azure RBAC. The identity needs the appropriate permission on the target Key Vault.

---

# 5. Create Kubernetes ServiceAccount

The ServiceAccount is created inside AKS using Kubernetes YAML.

Create:

### `serviceaccount.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount

metadata:
  name: akkc-pod-sa
  namespace: akkc

  annotations:
    azure.workload.identity/client-id: "95251e3e-a73e-42c9-b84a-d3c1b85e6fc0"
```

Apply:

```bash
kubectl apply -f serviceaccount.yaml
```

Verify:

```bash
kubectl get serviceaccount akkc-pod-sa -n akkc
```

The annotation connects the Kubernetes ServiceAccount to the Azure Managed Identity.

```text
ServiceAccount
      │
      │ azure.workload.identity/client-id
      ▼
User-Assigned Managed Identity
```

---

# 6. Configure the Deployment

The workload must use the ServiceAccount.

Create:

### `deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: kv-secret-reader
  namespace: akkc

spec:
  replicas: 1

  selector:
    matchLabels:
      app: kv-secret-reader

  template:
    metadata:
      labels:
        app: kv-secret-reader
        azure.workload.identity/use: "true"

    spec:
      serviceAccountName: akkc-pod-sa

      containers:
        - name: app
          image: nginx

          env:
            - name: LOVE_SECRET
              valueFrom:
                secretKeyRef:
                  name: kv-secret
                  key: LOVE_SECRET

            - name: HATE_SECRET
              valueFrom:
                secretKeyRef:
                  name: kv-secret
                  key: HATE_SECRET

          volumeMounts:
            - name: secrets-store
              mountPath: /mnt/secrets
              readOnly: true

      volumes:
        - name: secrets-store
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true

            volumeAttributes:
              secretProviderClass: azure-kv
```

Apply:

```bash
kubectl apply -f deployment.yaml
```

Check:

```bash
kubectl get pods -n akkc
```

---

# 7. Why `azure.workload.identity/use: "true"`?

This label tells Azure Workload Identity that the Pod should participate in workload identity.

```yaml
labels:
  azure.workload.identity/use: "true"
```

It must be present in the **Pod template**:

```yaml
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
```

Not merely on the Deployment itself.

---

# 8. How the Complete Flow Works

When the Pod starts:

```text
                    AKS
                     │
                     ▼
                Deployment
                     │
                     ▼
                   Pod
                     │
                     │
             ServiceAccount
              akkc-pod-sa
                     │
                     ▼
          Azure Workload Identity
                     │
                     ▼
               OIDC Token
                     │
                     ▼
             Microsoft Entra ID
                     │
                     ▼
       User-Assigned Managed Identity
          aks-workload-identity
                     │
                     ▼
              Azure Key Vault
                     │
                     ▼
              Read Secret
```

There are **no Azure client secrets or passwords stored in the Pod**.

---

# 9. Key Vault + Secrets Store CSI Driver

The Pod uses:

```yaml
volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: azure-kv
```

The CSI driver mounts secrets from Azure Key Vault into the Pod:

```text
Azure Key Vault
      │
      ▼
Secrets Store CSI Driver
      │
      ▼
/mnt/secrets
```

For example:

```bash
kubectl exec -it <pod-name> -n akkc -- ls /mnt/secrets
```

---

# 10. Kubernetes Secret vs Key Vault Secret

There are two different concepts here.

### Azure Key Vault Secret

The actual secret can live in:

```text
Azure Key Vault
```

Example:

```text
LOVE_SECRET = I love Kubernetes
HATE_SECRET = Manual deployments
```

### Kubernetes Secret

If your `SecretProviderClass` contains `secretObjects`, the CSI driver can also synchronize the Key Vault secret into a Kubernetes Secret:

```text
Azure Key Vault
      │
      ▼
Secrets Store CSI Driver
      │
      ▼
Kubernetes Secret
      │
      ▼
Environment Variable
```

Your Deployment then uses:

```yaml
env:
  - name: LOVE_SECRET
    valueFrom:
      secretKeyRef:
        name: kv-secret
        key: LOVE_SECRET
```

Important:

> **Mounting a secret through the CSI volume and creating a Kubernetes Secret are separate behaviors.**
> The `secretKeyRef` environment variables require the Kubernetes Secret `kv-secret` to exist.

---

# 11. Useful Verification Commands

### Check AKS nodes

```bash
kubectl get nodes
```

### Check ServiceAccount

```bash
kubectl get sa akkc-pod-sa -n akkc -o yaml
```

### Check Deployment

```bash
kubectl get deployment kv-secret-reader -n akkc
```

### Check Pods

```bash
kubectl get pods -n akkc
```

### Check Pod details

```bash
kubectl describe pod <pod-name> -n akkc
```

### Check mounted secrets

```bash
kubectl exec -it <pod-name> -n akkc -- ls -la /mnt/secrets
```

### Check environment variables

```bash
kubectl exec -it <pod-name> -n akkc -- env | grep SECRET
```

---

# 12. Portal vs Kubernetes

| Task                                  | Where?                               |
| ------------------------------------- | ------------------------------------ |
| Enable OIDC Issuer                    | Azure Portal → AKS                   |
| Enable Workload Identity              | Azure Portal → AKS                   |
| Create User-Assigned Managed Identity | Azure Portal → Managed Identities    |
| Create Federated Identity Credential  | Azure Portal → Managed Identity      |
| Assign Azure RBAC                     | Azure Portal → Target Resource → IAM |
| Create ServiceAccount                 | Kubernetes YAML / kubectl            |
| Configure Deployment                  | Kubernetes YAML                      |
| Configure CSI volume                  | Kubernetes YAML                      |
| Configure SecretProviderClass         | Kubernetes YAML                      |

---

# 13. Important Components to Remember

```text
AKS
 │
 ├── OIDC Issuer
 │
 ├── Workload Identity
 │
 └── Kubernetes ServiceAccount
          │
          ▼
   Federated Identity Credential
          │
          ▼
   User-Assigned Managed Identity
          │
          ▼
       Azure RBAC
          │
          ▼
     Azure Key Vault
          │
          ▼
 Secrets Store CSI Driver
          │
          ▼
        Pod
```

### Simple memory trick

```text
OIDC
 ↓
Trust

Federated Credential
 ↓
Mapping / Trust Relationship

Managed Identity
 ↓
Azure Identity

RBAC
 ↓
Permission

CSI Driver
 ↓
Secret Mount / Sync

ServiceAccount
 ↓
Kubernetes Identity
```

---

# 14. Interview One-Liner

> **"In the Azure Portal, I enable OIDC and Workload Identity on AKS, create a User-Assigned Managed Identity, create a Federated Identity Credential for the Kubernetes ServiceAccount, and assign the required RBAC role to the identity. The ServiceAccount, SecretProviderClass, and Pod/Deployment configuration are then created in Kubernetes."**

---

# 15. End-to-End Summary

The complete implementation is:

```text
1. Enable OIDC + Workload Identity
              ↓
2. Create User-Assigned Managed Identity
              ↓
3. Create Federated Identity Credential
              ↓
4. Assign Key Vault RBAC
              ↓
5. Create Kubernetes ServiceAccount
              ↓
6. Annotate ServiceAccount with Client ID
              ↓
7. Configure Deployment
              ↓
8. Add azure.workload.identity/use: "true"
              ↓
9. Use Secrets Store CSI Driver
              ↓
10. Access secrets from Azure Key Vault
```

The major benefit is:

```text
NO Client Secret
NO Password
NO Azure Credentials inside Pod
```

Instead:

```text
Kubernetes ServiceAccount
          ↓
       OIDC Token
          ↓
 Azure Workload Identity
          ↓
 Managed Identity
          ↓
    Azure RBAC
          ↓
   Azure Resource
```


This is the recommended identity-based approach for securely accessing Azure resources from workloads running in AKS.
