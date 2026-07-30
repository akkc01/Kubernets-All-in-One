# Traffic Flow-

        Internet
            │
            ▼
        Azure ALB / Gateway Fabric
            │
            ▼
        GatewayClass (Cluster Scoped)
            │
            ▼
        Gateway (Namespace: akkc-gateway)
            │
            ├──────────────┬──────────────┐
            │              │              │
            ▼              ▼              ▼
        HTTPRoute      HTTPRoute      HTTPRoute
        (main-app)      (app1)         (app2)
            │              │              │
            ▼              ▼              ▼
        Service        Service        Service
            │              │              │
            ▼              ▼              ▼
        Deployment    Deployment    Deployment
            │              │              │
        2 Pods         2 Pods         2 Pods


# Directory Structure--

gateway-api/
│
├── namespaces/
│   └── namespace.yaml
│
├── gateway/
│   ├── gatewayclass.yaml
│   └── gateway.yaml
│
├── main-app/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── httproute.yaml
│
├── app1/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── httproute.yaml
│
├── app2/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── httproute.yaml
│
└── README.md





# Deployment Order
kubectl apply -f namespace.yaml

kubectl apply -f app-gateway.yaml

kubectl apply -f .