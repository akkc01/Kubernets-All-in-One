Service
    A Service in Kubernetes is an abstraction that defines how to access a set of Pods — typically by name or IP — regardless of where the Pods are running.
    Pods are ephemeral (they come and go), but a Service provides a stable endpoint to access them.

Incoming request --> service --> Pod
	• Pods associated with a service using Selector.
	• Service Provided the load balancing mechanism in the
           simple Round Robin Load balancing. Means send the 
           requested divide equally to each pod, one bye one.
								
Why Services?
	• Pods have dynamic IPs (they change)
	• Services group pods using labels
	• Services provide a stable DNS name/IP
	• Enable load balancing between multiple pod replicas


Types of Services:
		a. ClusterIP (default)
		b. NodePort
		c. LoadBalancer
		d. ExternalName
		e. Headless Service (clusterIP: None)


How Service types work together -
	Incoming request -->az load Balancer --> node port--> cluster IP --> Pod
	

Summary Table:
	Type	Internal Access	External Access	Load Balancer	DNS Alias	Pod Discovery
	ClusterIP	✅	❌	❌	❌	❌
	NodePort	✅	✅	❌	❌	❌
	LoadBalancer	✅	✅ (Cloud only)	✅	❌	❌
	ExternalName	❌	✅ (DNS only)	❌	✅	❌
	Headless	✅	❌	❌	❌	✅
	
	
    
	
Apply and verify:
    kubectl apply -f service.yaml
    kubectl get svc
    kubectl describe svc nginx-service
    kubectl get endpoints nginx-service
