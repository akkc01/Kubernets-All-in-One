helm install nginx-custom ingress-nginx/ingress-nginx \
  --namespace ingress-nginx-akkc \
  --create-namespace \
  --set controller.ingressClass=nginx-akkc \
  --set controller.ingressClassResource.name=nginx-akkc \
  --set controller.ingressClassResource.controllerValue="k8s.io/ingress-nginx-akkc" \
  --set controller.ingressClassByName=true \
  --set controller.electionID=ingress-nginx-akkc-leader \
  --set controller.controllerClass="k8s.io/ingress-nginx-akkc"


  kubectl delete ingress --all -n default


az network lb list -g MC_aks-rg_aks-tets_eastus -o table
  MC_aks-rg_aks-tets_eastus


kubectl get svc -n ingress-nginx ingress-nginx-controller -o yaml | grep -A5 "10254\|healthz"

kubectl annotate svc ingress-nginx-controller -n ingress-nginx \
  service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path=/healthz --overwrite
service/ingress-nginx-controller annotated

kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.metadata.annotations}'
{"meta.helm.sh/release-name":"ingress-nginx","meta.helm.sh/release-namespace":"ingress-nginx","service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path":"/healthz"}%



---------------------------------
ye sab tab karna pad raha hai jab Azure Load Balancer ka health probe ingress-nginx ko healthy detect nahi kar paa raha.

-------------
Option 1:  externalTrafficPolicy ko Local set karo. Ye AKS + ingress-nginx ka official recommended solution hai.


**1. Service edit karo:**
```bash
kubectl edit svc ingress-nginx-controller -n ingress-nginx
```

Vim editor khulega. Andar `spec:` section me `externalTrafficPolicy: Cluster` line dhoondo (search karne ke liye `/externalTrafficPolicy` type karo, Enter dabao). Us line ko change karo:

```yaml
externalTrafficPolicy: Local
```

Save karke exit karo — `Esc` dabao, fir type karo `:wq` aur Enter dabao.

**2. Confirm karo change apply hua:**
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.externalTrafficPolicy}'
```
Output `Local` aana chahiye.

**3. Naya `healthCheckNodePort` check karo (ye automatically create hota hai):**
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.healthCheckNodePort}'
```
Ek number aayega (jaise `32xxx`) — ye wahi port hai jo ab Azure LB health check ke liye use karega.

**4. 1-2 minute wait karo** — Azure ko apna health probe configuration automatically update karne me thoda time lagta hai.

**5. Portal pe check karo:**
Load Balancer `kubernetes` → Backend pools → Health status → **Healthy** aana chahiye.

**6. Fir curl test karo:**
```bash
curl -v -H "Host: theakkc.space" http://4.156.114.57/
```

Ye kaam karke batao kya result aata hai — health status aur curl dono.




------------
Option 2: Port 10254 manually service me add karo (nginx ka built-in /healthz)
Nginx ingress controller already /healthz endpoint expose karta hai container ke andar port 10254 pe — bas service me wo port missing hai. Ise add kar do:
bash
kubectl edit svc ingress-nginx-controller -n ingress-nginx
spec.ports list me ye entry add karo:
yaml
  - name: healthz
    port: 10254
    protocol: TCP
    targetPort: 10254

Fir annotation wapas lagao (jo tumne pehle lagaya tha):


kubectl annotate svc ingress-nginx-controller -n ingress-nginx \
  service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path=/healthz --overwrite
Ab Azure LB port 10254 pe /healthz hit karega jo bina Host header ke bhi hamesha 200 OK deta hai. Isse ingress rule host-based rehne ke bawajood health probe pass hoga.

---------------
Option 3: Default backend Ingress rule add karo (host ke bina, catch-all) ya
Ek dusra Ingress resource bana do jisme koi host na ho — ye tumhare actual host-based ingress ke saath co-exist karega:
yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: default-health-ingress
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: akkc-service
                port:
                  number: 80
Isse jab bhi LB bina Host header ke / hit karega, ye catch-all rule match ho jayegi aur 200 OK milega — health probe pass ho jayega, jabki tumhara real host-based rule (theakkc.space) waisa hi kaam karta rahega alag se.
Meri recommendation: externalTrafficPolicy: Local sabse standard/production-grade fix hai kyunki ye Kubernetes-native mechanism hai aur AKS docs bhi yahi suggest karte hain. Lekin agar kisi wajah se wo use nahi karna (jaise Local policy traffic distribution thoda change kar deti hai — sirf usi node pe traffic jata hai jaha pod ho, source IP preserve hota hai), to Option 2 (port 10254 add karna) bhi equally reliable hai aur zyada explicit control deta hai.