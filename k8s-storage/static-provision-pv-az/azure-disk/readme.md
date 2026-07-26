**If your Azure Managed Disk is located in a different Resource Group than your AKS cluster, you must grant the AKS identity the required Azure RBAC permissions on that Resource Group (or on the specific disk).**

In your case:

* **AKS Cluster:** `aks-cluster-dev`
* **Disk Resource Group:** `stg-test-dev-rg`
* **AKS uses its Cluster Identity to attach/detach Azure Disks.**

Therefore, the Cluster Identity must have permissions to access the disk.

### Recommended approach

Grant the **Contributor** role to the AKS Cluster Identity on the Resource Group that contains the disk:

```bash
az role assignment create \
  --assignee-object-id <AKS_CLUSTER_OBJECT_ID> \
  --assignee-principal-type ServicePrincipal \
  --role Contributor \
  --scope /subscriptions/<subscription-id>/resourceGroups/stg-test-dev-rg
```

### Alternatively (Least Privilege)

If you want to grant access only to a single disk:

```bash
az role assignment create \
  --assignee-object-id <AKS_CLUSTER_OBJECT_ID> \
  --assignee-principal-type ServicePrincipal \
  --role Contributor \
  --scope /subscriptions/<subscription-id>/resourceGroups/stg-test-dev-rg/providers/Microsoft.Compute/disks/<disk-name>
```

### Why is this required?

When a pod uses a **static Azure Managed Disk**, the Azure Disk CSI driver calls the Azure Compute API to:

* Read the disk metadata
* Attach the disk to the AKS node
* Detach the disk when it is no longer needed

If the AKS identity does not have permission on the disk's Resource Group, the attach operation fails with an error similar to:

```text
AuthorizationFailed:
The client does not have authorization to perform
'Microsoft.Compute/disks/read'
```

### Best Practice

* If the disk is in the **same Resource Group** where AKS already has the necessary permissions, no additional role assignment is typically required.
* If the disk is in a **different Resource Group**, grant the AKS Cluster Identity the required RBAC permissions (such as **Contributor**) on that Resource Group or on the specific disk.
