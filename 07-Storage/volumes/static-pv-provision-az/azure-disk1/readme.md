Azure Disk – Can multiple PVCs use one PV?
Not supported for normal shared mounting
Azure Managed Disks are block storage devices. They are generally designed to be attached to one node at a time.

For example:







learn.microsoft.com


Suppose you create:
- azure-disk-pv
- pvc-1
- pvc-2
You cannot bind both PVCs to the same PV.

Why?

Because Kubernetes PV-to-PVC binding is one-to-one. A PV can be bound to only one PVC at a time.

Supported access modes:
Access mode	Azure Disk
ReadWriteOnce (RWO)	Yes
ReadOnlyMany (ROX)	Driver-dependent; generally not supported for Azure Disk
ReadWriteMany (RWX)	No
ReadWriteOncePod (RWOP)	Yes, with supported CSI driver

Important: RWO means read-write access from a single node, not necessarily a single Pod. Multiple Pods on the same node can use an RWO volume, subject to the CSI and Kubernetes configuration.
2. Azure Files – Can multiple PVCs use one PV?
Supported with RWX
Azure Files is a network-based file storage service. Unlike Azure Disk, multiple Pods can access the same file share, even when they are running on different AKS nodes.







learn.microsoft.com


For example:
                 Azure Storage Account
                         |
                    File Share
                         |
                    Azure PV
                    (RWX)
                         |
              +----------+----------+
              |                     |
            PVC-1                 PVC-2
              |                     |
           Pod-1                  Pod-2
          Node-1                 Node-2
              |                     |
              +----------+----------+
                         |
                  Shared File Data


Both Pods can read and write to the same files.

Azure Files access modes:
Access mode	Supported
ReadWriteOnce	Yes
ReadOnlyMany	Yes
ReadWriteMany	Yes
ReadWriteOncePod	No


Microsoft Learn+1
3. Azure Disk vs Azure Files
Feature	Azure Disk	Azure Files
Storage type	Block storage	File storage
Protocol	Block device	SMB / NFS
Multiple nodes	No	Yes
RWX	No	Yes
Multiple PVCs per PV	No	No
Multiple Pods sharing data	Same node, subject to driver	Yes
Best for	Databases, application data	Shared files, uploads, reports

Important distinction: Azure Files supports multiple Pods sharing one PVC. However, Kubernetes still maintains a 1:1 PV-to-PVC binding.

So, if you want multiple PVCs, you generally create multiple PVs referencing the same Azure File Share, with unique volumeHandle values. Each PV binds to its own PVC.