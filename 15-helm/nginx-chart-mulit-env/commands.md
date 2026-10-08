# varify the chart using the following commands:
helm lint ./nginx-app -f ./nginx-app/values-dev.yaml
helm template ./nginx-app -f ./nginx-app/values-dev.yaml
helm template nginx-dev ./nginx-app -f ./nginx-app/values-dev.yaml

# Command to install the chart
helm install nginx-dev ./nginx-app -f ./nginx-app/values-dev.yaml
helm install nginx-stage ./nginx-app -f ./nginx-app/values-stage.yaml
helm install nginx-prod ./nginx-app -f ./nginx-app/values-prod.yaml
helm install nginx-prod ./nginx-app -f ./nginx-app/values-prod.yaml  # Fails: resource already exists

# to varify the installation, you can use the following commands:
helm list
helm status nginx-dev
helm history nginx-dev

# Best Practice: Use the --namespace flag to install the chart in a specific namespace. 
# For example, to install the chart in the dev namespace, you can use the following command:
kubectl create namespace dev
helm install nginx-dev ./nginx-app -f ./nginx-app/values-dev.yaml --namespace dev

# k8s varify the installation, you can use the following commands:
kubectl get deploy,svc -n dev
kubectl get pods -n dev

# unstall the chart using the following command:
helm uninstall nginx-dev --namespace dev