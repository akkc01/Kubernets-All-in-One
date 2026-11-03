kubectl port-forward -n dev pod/firefox 5800:5800
kubectl port-forward svc/mario -n dev 8080:8080
kubectl port-forward -n dev pod/firefox 5800:5800


helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
-n monitoring \
--create-namespace

kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090


kubectl port-forward svc/monitoring-grafana \
-n monitoring \
3000:80


kubectl get secret monitoring-grafana \
-n monitoring \
-o jsonpath="{.data.admin-password}" | base64 -d

kubectl get pods -n monitoring



Run in Prometheus---

sum by (pod) (
  rate(container_cpu_usage_seconds_total{namespace="dev"}[5m])
)


sum by (pod) (
  container_memory_working_set_bytes{namespace="dev"}
)

kube_pod_info