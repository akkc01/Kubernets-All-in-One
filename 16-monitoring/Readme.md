````markdown
# Prometheus & Grafana Installation on Kubernetes

## Prerequisites

- Kubernetes Cluster (AKS, EKS, GKE, kubeadm, Kind, Minikube)
- kubectl
- Helm

Verify:

```bash
kubectl get nodes
helm version
```

---

## 1. Add Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

## 2. Create Namespace

```bash
kubectl create namespace monitoring
```

---

## 3. Install kube-prometheus-stack

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring
```

Verify installation:

```bash
kubectl get pods -n monitoring
```

---

## 4. Access Prometheus

```bash
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring
```

Open:

```
http://localhost:9090
```

---

## 5. Access Grafana

Port Forward:

```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

Open:

```
http://localhost:3000
```

---

## 6. Grafana Login

**Username**

```
admin
```

**Get Password**

```bash
kubectl get secret -n monitoring prometheus-grafana \
-o jsonpath="{.data.admin-password}" | base64 -d
```

---

## 7. Verify Prometheus Datasource

Navigate:

```
Connections → Data Sources → Prometheus
```

Click **Save & Test**.

---

## 8. Import Dashboards

Go to:

```
Dashboards → Import
```

Popular Dashboard IDs:

| Dashboard | ID |
|-----------|----|
| Node Exporter Full | 1860 |
| Kubernetes Cluster Monitoring | 6417 |
| Kubernetes Views (Pods) | 15760 |
| Kubernetes Views (Nodes) | 15759 |
| Kubernetes Views (Global) | 15757 |

Select **Prometheus** as the datasource and click **Import**.

---

## 9. Create Custom Dashboard

Navigate:

```
Dashboards → New Dashboard → Add Visualization
```

Example PromQL queries:

**Node Count**

```promql
count(kube_node_info)
```

**Running Pods**

```promql
count(kube_pod_status_phase{phase="Running"})
```

**CPU Usage**

```promql
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memory Usage**

```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
/
node_memory_MemTotal_bytes
* 100
```

Save the dashboard with your preferred name.

---

## 10. Uninstall

```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

---

## Components Installed

- Prometheus Operator
- Prometheus
- Alertmanager
- Grafana
- Node Exporter
- kube-state-metrics

These components provide complete Kubernetes monitoring, visualization, and alerting.
````
