Step 1: Connect to your AKS cluster
az login

az aks get-credentials \
  --resource-group <resource-group> \
  --name <aks-cluster-name>

Verify:

kubectl get nodes


Step 2: Add the Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update


Step 3: Install the Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace


Step 4: Verify installation
kubectl get pods -n ingress-nginx

You should see something like:

ingress-nginx-controller-xxxxx   Running


Step 5: Get the external IP
    kubectl get svc -n ingress-nginx

Example:

NAME                                 TYPE           EXTERNAL-IP
ingress-nginx-controller             LoadBalancer   20.x.x.x

The EXTERNAL-IP is the public IP you can use to access your applications.


# Commnads
kubectl apply -f deployment-app1.yaml
kubectl apply -f deployment-app2.yaml
kubectl apply -f service-app1.yaml
kubectl apply -f service-app2.yaml
kubectl apply -f ingress.yaml