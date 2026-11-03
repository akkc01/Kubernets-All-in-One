## 2. What Is a Taint?

A **Taint** is a property applied to a Kubernetes node.

It tells the Kubernetes scheduler that the node should reject Pods that do not have a matching toleration.

Syntax:

```
kubectl taint nodes <NODE_NAME> key=value:effect
```

Example:

```
kubectl taint nodes worker-node-1 environment=production:NoSchedule
```

This taint means:

- Key: `environment`
- Value: `production`
- Effect: `NoSchedule`

Pods without a matching toleration will not be scheduled on this node.
