Got it bro. You need a standalone `README.md` explaining Azure Workload Identity, starting with what it is, why we need it, how authentication works, and how to configure it on an existing AKS cluster.

You can directly copy this into your GitHub repository.

# Azure Workload Identity with AKS

## 1. What is Azure Workload Identity?

Azure Workload Identity is a passwordless authentication mechanism that allows applications running inside Azure Kubernetes Service (AKS) to securely access Azure resources.

It enables Kubernetes workloads to authenticate with Microsoft Entra ID using federated identity instead of storing Azure client secrets or Service Principal credentials inside Kubernetes Pods.

Applications can use Workload Identity to access:

- Azure Key Vault
- Azure Storage Account
- Azure Container Registry
- Azure SQL Database
- Azure Service Bus
- Other Azure services that support Microsoft Entra authentication

### Example

Suppose an application running inside an AKS Pod needs to retrieve database credentials from Azure Key Vault.

Without Workload Identity, we might need to store Azure credentials inside Kubernetes.

With Workload Identity, the Pod uses its Kubernetes ServiceAccount to authenticate with Microsoft Entra ID and obtain an Azure access token.

No client secret needs to be stored inside the Pod.

---

## 2. Why Do We Need Workload Identity?

Traditional authentication methods often require storing credentials inside applications or Kubernetes configurations.

For example:

```
Application Pod
      |
      | Client ID
      | Client Secret
      |
      v
Microsoft Entra ID
      |
      v
Azure Resources
```

This approach introduces security risks:

- Client secrets can accidentally leak through YAML files.
- Credentials require periodic rotation.
- Secret management becomes difficult across environments.
- Managing credentials across multiple applications increases operational overhead.

### Workload Identity solves these problems.

```
Application Pod
      |
      v
Kubernetes ServiceAccount
      |
      v
AKS OIDC Issuer
      |
      v
Microsoft Entra ID
      |
      v
Azure Managed Identity
      |
      v
Azure Resources
```

The workload authenticates using federated identity instead of a stored client secret.

---

## 3. Azure Workload Identity Architecture

```
                  AZURE CLOUD
                       |
                       |
             +--------------------+
             | Microsoft Entra ID |
             +--------------------+
                       |
                       |
              Federated Identity
                  Credential
                       |
                       |
             +--------------------+
             | User Assigned      |
             | Managed Identity   |
             +--------------------+
                       |
                       |
                Azure Resources
                       |
                       v
                Azure Key Vault
                       ^
                       |
                       |
                  AKS CLUSTER
                       |
             +--------------------+
             | Application Pod    |
             +--------------------+
                       |
                       |
             Kubernetes ServiceAccount
                       |
                       |
                 OIDC Issuer
                       |
                       |
              Projected Service
                 Account Token
                       |
                       |
              Federated Token
                   Exchange
                       |
                       v
               Microsoft Entra ID
```

### Architecture Components

| Component                     | Responsibility                                        |
| ----------------------------- | ----------------------------------------------------- |
| AKS                           | Runs Kubernetes workloads                             |
| OIDC Issuer                   | Provides a trusted identity issuer                    |
| ServiceAccount                | Represents a Kubernetes workload                      |
| Projected Token               | Provides the workload's identity proof                |
| Federated Identity Credential | Establishes trust between AKS and Azure               |
| Managed Identity              | Represents the workload in Azure                      |
| Microsoft Entra ID            | Validates federated identity and issues access tokens |
| Azure RBAC                    | Controls permissions to Azure resources               |

---

## 4. How Does Workload Identity Work?

The authentication process involves the following steps:

### Step 1: Create a Kubernetes ServiceAccount

A Kubernetes ServiceAccount identifies a workload inside the cluster.

Example:

```
apiVersion: v1
kind: ServiceAccount

metadata:
  name: aks-workload-sa
  namespace: dev

  annotations:
    azure.workload.identity/client-id: "<MANAGED_IDENTITY_CLIENT_ID>"
```

### Step 2: AKS OIDC Issuer

AKS provides an OpenID Connect (OIDC) issuer.

The issuer provides signed tokens that identify Kubernetes workloads.

These tokens contain identity information such as:

- Issuer
- Subject
- Audience

Example subject:

```
system:serviceaccount:dev:aks-workload-sa
```

### Step 3: Federated Identity Credential

A Federated Identity Credential establishes trust between the AKS OIDC issuer and the Azure Managed Identity.

The configuration includes:

| Field    | Example                    |
| -------- | -------------------------- |
| Issuer   | AKS OIDC issuer URL        |
| Subject  | system:serviceaccount:dev  |
| Audience | api://AzureADTokenExchange |

Microsoft Entra ID uses these values to validate the Kubernetes workload's identity.

### Step 4: Token Exchange

When the Pod starts, the Workload Identity webhook injects the required authentication configuration.

The workload receives a projected ServiceAccount token.

An Azure SDK or another supported client exchanges this token with Microsoft Entra ID.

Microsoft Entra ID validates the token against the Federated Identity Credential and issues an Azure access token for the associated Managed Identity.

### Step 5: Access Azure Resources

The application uses the Azure access token to access resources such as:

- Azure Key Vault
- Azure Storage
- Azure SQL

Access is granted only when the Managed Identity has the necessary Azure RBAC permissions.

---

## 5. How to Configure Workload Identity on Existing AKS

### Prerequisites

- Existing AKS cluster
- Azure subscription
- Azure CLI
- kubectl
- Permission to manage AKS, Managed Identities and role assignments

### Step 1: Enable OIDC and Workload Identity

Open Azure Portal.

1. Navigate to Kubernetes Services.
2. Select your existing AKS cluster.
3. Open Security configuration.
4. Enable OIDC Issuer.
5. Enable Workload Identity.
6. Save the configuration.

Verify that both features are enabled.

### Step 2: Create User Assigned Managed Identity

Open:

Azure Portal → Managed Identities → Create.

Create a new identity:

```
Name: aks-workload-identity
Type: User Assigned Managed Identity
```

After creation, collect:

- Client ID
- Principal ID
- Tenant ID

### Step 3: Create Federated Identity Credential

Open:

Azure Portal → Managed Identities → aks-workload-identity → Federated Credentials.

Select Add Credential.

Choose Kubernetes accessing Azure resources.

Configure:

```
Cluster Issuer URL:
<AKS_OIDC_ISSUER_URL>

Namespace:
dev

Service Account:
aks-workload-sa

Audience:
api://AzureADTokenExchange
```

The expected subject is:

```
system:serviceaccount:dev:aks-workload-sa
```

Save the credential.

### Step 4: Create Kubernetes Namespace

```
kubectl create namespace dev
```

### Step 5: Create ServiceAccount

Create `service-account.yaml`:

```
apiVersion: v1
kind: ServiceAccount

metadata:
  name: aks-workload-sa
  namespace: dev

  annotations:
    azure.workload.identity/client-id: "<CLIENT_ID>"
```

Apply:

```
kubectl apply -f service-account.yaml
```

### Step 6: Create a Deployment

Create `deployment.yaml`:

```
apiVersion: apps/v1
kind: Deployment

metadata:
  name: workload-identity-demo
  namespace: dev

spec:
  replicas: 1

  selector:
    matchLabels:
      app: workload-identity-demo

  template:
    metadata:
      labels:
        app: workload-identity-demo
        azure.workload.identity/use: "true"

    spec:
      serviceAccountName: aks-workload-sa

      containers:
        - name: app
          image: nginx:1.27

          ports:
            - containerPort: 80
```

Apply:

```
kubectl apply -f deployment.yaml
```

Check the Pod:

```
kubectl get pods -n dev
```

### Step 7: Verify Workload Identity Injection

Inspect the Pod:

```
kubectl describe pod <POD_NAME> -n dev
```

Check the environment variables:

```
kubectl exec -n dev <POD_NAME> -- env | grep AZURE
```

You should find relevant variables such as:

```
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_FEDERATED_TOKEN_FILE
```

The projected token is mounted into the container filesystem and is used by supported Azure SDK authentication flows.

**Important:** NGINX does not automatically authenticate to Azure just because these variables are injected. The application must use an Azure SDK or another supported Workload Identity authentication client.

---

## 6. Workload Identity with Azure Key Vault

After configuring Workload Identity, we can integrate Azure Key Vault.

The authentication and retrieval process is:

```
AKS Pod
   |
   v
ServiceAccount
   |
   v
Workload Identity
   |
   v
Microsoft Entra ID
   |
   v
Managed Identity
   |
   v
Azure Key Vault
   |
   v
Retrieve Secrets
```

To implement this integration, we additionally configure:

1. Azure Key Vault.
2. Key Vault Secrets User RBAC role.
3. Secrets Store CSI Driver.
4. Azure Key Vault Provider.
5. SecretProviderClass.

The CSI Driver uses the workload's federated identity to authenticate with Azure and retrieve secrets.

---

## 7. Workload Identity vs Managed Identity vs ServiceAccount

These technologies work together but have different responsibilities.

| Technology                    | Responsibility                                                    |
| ----------------------------- | ----------------------------------------------------------------- |
| Kubernetes ServiceAccount     | Identifies workloads inside Kubernetes                            |
| Azure Managed Identity        | Provides an identity in Microsoft Entra ID                        |
| Workload Identity             | Establishes federated authentication between Kubernetes and Azure |
| Federated Identity Credential | Defines which Kubernetes identity Azure trusts                    |
| OIDC Issuer                   | Issues trusted identity tokens                                    |

### Simple Explanation

- ServiceAccount: Who are you inside Kubernetes?
- Managed Identity: Which Azure identity represents you?
- Workload Identity: How do you prove your identity to Azure?
- Federated Credential: Which Kubernetes identity is trusted by Azure?

---

## 8. Workload Identity vs Service Principal

| Feature             | Service Principal with Client Secret | Workload Identity           |
| ------------------- | ------------------------------------ | --------------------------- |
| Client Secret       | Required                             | Not required                |
| Credential Storage  | Required                             | No client secret storage    |
| Authentication      | Client credentials                   | Federated token exchange    |
| Credential Rotation | Required                             | No client secret to rotate  |
| AKS Integration     | Manual configuration                 | Native integration          |
| Security            | Credential management overhead       | Passwordless authentication |

---

## 9. Workload Identity vs Azure Key Vault CSI Driver

These are different technologies and should not be confused.

| Feature                           | Workload Identity | Secrets Store CSI Driver      |
| --------------------------------- | ----------------- | ----------------------------- |
| Primary purpose                   | Authentication    | Secret retrieval and mounting |
| Token exchange                    | Yes               | Uses workload authentication  |
| Azure identity                    | Yes               | Uses configured identity      |
| Secret retrieval                  | No, not by itself | Yes                           |
| Mount secrets as files            | No                | Yes                           |
| Kubernetes Secret synchronization | No                | Optional                      |

**Workload Identity provides authentication. CSI Driver provides secret retrieval and mounting.**

---

## 10. Best Practices

1. Use User Assigned Managed Identity for workload authentication.
2. Avoid storing Service Principal client secrets in Kubernetes.
3. Use separate Managed Identities for dev, QA and production.
4. Restrict Federated Identity Credentials to the required namespace and ServiceAccount.
5. Assign minimum required Azure RBAC permissions.
6. Protect Kubernetes ServiceAccounts using RBAC.
7. Monitor Managed Identity and Key Vault access.
8. Use Azure Key Vault for centralized secret management.
9. Enable secret rotation where applicable.
10. Avoid printing access tokens and credentials in logs.

---

## 11. Troubleshooting

| Error                    | Possible Cause                                                |
| ------------------------ | ------------------------------------------------------------- |
| Identity not found       | Incorrect Managed Identity Client ID                          |
| AADSTS70021              | Federated credential mismatch                                 |
| Forbidden                | Missing Azure RBAC permission                                 |
| Token exchange failure   | Incorrect OIDC issuer or audience                             |
| Missing AZURE_CLIENT_ID  | Workload Identity webhook not configured or Pod label missing |
| Secret retrieval failure | Key Vault permission or network issue                         |

Useful commands:

```
kubectl get pods -n dev
```

```
kubectl get serviceaccounts -n dev
```

```
kubectl describe pod <POD_NAME> -n dev
```

```
kubectl get events -n dev --sort-by='.lastTimestamp'
```

---

## 12. Key Takeaways

Azure Workload Identity provides secure, passwordless authentication for Kubernetes workloads accessing Azure resources.

It uses:

- AKS OIDC Issuer
- Kubernetes ServiceAccount
- Federated Identity Credential
- Microsoft Entra ID
- User Assigned Managed Identity

The most important concept is that Kubernetes workloads do not need to store Azure client secrets to authenticate with Azure.

This makes Workload Identity a recommended authentication approach for modern AKS applications.

---

## 13. Official Documentation

- [Azure Workload Identity Overview](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [Deploy Workload Identity on AKS](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster)
- [Azure Managed Identities](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)
- [Microsoft Entra Federated Identity Credentials](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)

**Technology Stack:** Azure | AKS | Kubernetes | Microsoft Entra ID | Workload Identity | Managed Identity | OIDC | Federated Identity

This README covers Workload Identity independently. Your next README can cover the separate integration: Workload Identity + Azure Key Vault + Secrets Store CSI Driver.