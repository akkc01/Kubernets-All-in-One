K8s Storage -
Kubernetes storage is broadly divided into 2 main categories:

1. Ephemeral Storage (Temporary)
	Data exists only while the Pod is running
	Pod delete → data gone ❌

Types of Ephemeral Storage
1. emptyDir
	• Created when pod starts
	• Deleted when pod stops

emptyDir: {}
Use case:
	• Cache
	• Temp files

2. configMap (as volume)
	• Stores configuration data

3. secret (as volume)
	• Stores sensitive data

4. Downward API
	• Pod metadata expose karta hai

5. Container writable layer
	• Default storage inside container

Key Point
	Ephemeral = non-persistent


2. Persistent Storage (Permanent)
	Data survives pod restart/deletion 
 
Uses:
	• PV (PersistentVolume)
	• PVC (PersistentVolumeClaim)

Types of Persistent Storage
A. Node-based Storage
	1. hostPath
		○ Direct node path mount
		○ ❌ Not production safe
	
	2. Local Persistent Volume
		○ Node-local storage
		○ ✔ Uses PV/PVC
		○ ⚠ Node-bound

B. Network / Shared Storage
	3. NFS (Network File System)
		○ Shared storage across nodes
		○ ✔ RWX supported
	
	4. Azure Files (SMB)
		○ Cloud-based shared storage
		○ ✔ RWX
		○ Used in Azure Kubernetes Service
	
	5. AWS EFS / GCP Filestore
		○ Similar to NFS
		○ Cloud-managed file storage

C. Block Storage
	6. Azure Disk
		○ High performance
		○ ✔ RWO only
	
	7. AWS EBS / GCP Persistent Disk
		○ Similar to Azure Disk

D. Object Storage (Advanced)
	8. Azure Blob / S3
		○ Object storage
		○ Not full filesystem
		○ Used via CSI driver
	

Classification Summary -
Based on Behavior
	Type	Example
	Ephemeral	emptyDir, Secret
	Persistent	Disk, Files, NFS

Based on Location
	Type	Example
	Local	hostPath, Local PV
	Network	NFS, Azure Files
	Cloud	Azure Disk, EBS

Based on Access Mode
	Mode	Meaning
	RWO	One node
	RWX	Multiple nodes
	ROX	Read-only


What is a Persistent Volume (PV)?
Persistent Volume (PV) is storage inside your Kubernetes cluster that has been provisioned by an administrator or dynamically created by Kubernetes. It is a resource in the cluster just like a node is a cluster resource.

Think of it like a hard disk or cloud volume that is not tied to any pod. PV abstracts the underlying storage (local disk, NFS, cloud disk, etc.) and provides a persistent storage layer independent of the Pod lifecycle.


What is a Persistent Volume Claim (PVC)?
A Persistent Volume Claim is a request for storage by a pod/user (developer or application) in Kubernetes.
	• It’s how a Pod asks for storage resources (size, access mode).
	• A pod doesn’t use PV directly — instead, it uses a PVC to ask for storage (e.g., “I need 5GB to store my data”).
	• Kubernetes looks at the available PVs and gives the pod one that matches the PVC.



What is accessModes in Kubernetes?
In Kubernetes, every Persistent Volume (PV) and Persistent Volume Claim (PVC) must define how that volume can be accessed. This is done using accessModes.

	Access Mode	   Short Name	Meaning
	ReadWriteOnce	RWO	       One node can read/write. Multiple pods on the same node can use it.
	ReadOnlyMany	ROX	       Multiple nodes can mount it as read-only. Multiple nodes can only read
	ReadWriteMany	RWX	       Multiple nodes can mount it as read/write.
	ReadWriteOncePod RWOP   Volume can be mounted as read/write by only one Pod in the entire cluster.
			


kubectl describe deployment azurefile-app
kubectl describe pod azurefile-app-7c7cddf956-mds7n 
kubectl exec -it azurefile-app-7c7cddf956-mds7n -- /bin/bash

kubectl delete pv azurefile-pv.   # if terminal stuck use below command

kubectl patch pv azurefile-pv -p '{"metadata":{"finalizers":null}}'

echo anoopsa | base64 -d.   # jz(%  