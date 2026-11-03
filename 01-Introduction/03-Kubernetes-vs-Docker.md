# 🐳 Docker vs ☸️ Kubernetes -

<p align="center">
  <img src="https://img.shields.io/badge/Docker-Containerization-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Kubernetes-Container%20Orchestration-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />
  <img src="https://img.shields.io/badge/Level-Beginner%20to%20Advanced-2EA44F?style=for-the-badge" />
</p>

<p align="center">
  <b>Understand Containerization vs Container Orchestration</b>
</p>

---

## 📌 1. Introduction

Docker and Kubernetes are two important technologies in modern Cloud-Native and DevOps environments.

Although both work with containers, they solve different problems.

- **Docker** is a platform and ecosystem used to build, package, distribute, and run containerized applications.
- **Kubernetes** is an open-source container orchestration platform used to deploy, scale, manage, and maintain containerized applications across a cluster of machines.

In simple terms:

**Docker helps you create and run containers, while Kubernetes helps you manage containerized applications at scale.**

They are complementary technologies, not direct replacements for each other.

---

## 🐳 2. What is Docker?

Docker is a containerization platform that allows developers to package applications and their dependencies into lightweight, portable containers.

A container includes:

- Application code.
- Runtime dependencies.
- Libraries.
- Configuration.
- Required filesystem components.

Containers share the host operating system kernel but provide isolated execution environments.

### Why Do We Need Docker?

Imagine an application works perfectly on a developer's laptop but fails on a production server because of different dependencies or software versions.

Docker solves this problem by packaging the application and its dependencies into a consistent container image.

### Key Docker Components

| Component | Description |
|---|---|
| Docker Client | Provides the CLI interface to interact with Docker. |
| Docker Engine | Provides the container management environment. |
| Docker Daemon | Manages images, containers, networks, and volumes. |
| Docker Image | Read-only template used to create containers. |
| Docker Container | Running instance of an image. |
| Dockerfile | Instructions used to build an image. |
| Docker Registry | Stores and distributes container images. |
| Docker Compose | Defines and manages multi-container applications. |
| Docker Buildx | Provides advanced image-building capabilities, including multi-platform builds. |

### Docker Architecture

```text
             Developer
                 |
                 v
           Docker Client
             (docker CLI)
                 |
             REST API
                 |
                 v
          Docker Daemon
             (dockerd)
                 |
       +---------+---------+
       |         |         |
       v         v         v
     Images   Containers  Networks
       |         |         |
       +---------+---------+
                 |
                 v
          Docker Registry
        (Docker Hub / ACR)
```

### Important Docker Commands

```bash
# Check Docker version
docker version

# Pull an image
docker pull nginx:latest

# List images
docker images

# Run a container
docker run -d -p 8080:80 --name nginx nginx:latest

# List running containers
docker ps

# View container logs
docker logs nginx

# Access container shell
docker exec -it nginx sh

# Stop container
docker stop nginx

# Remove container
docker rm nginx
```

---

## ☸️ 3. What is Kubernetes?

Kubernetes is an open-source container orchestration platform originally developed by Google and now maintained by the Cloud Native Computing Foundation (CNCF).

It automates the deployment, scaling, networking, and management of containerized applications.

### Why Do We Need Kubernetes?

Imagine you have a microservices application containing 20 services and each service runs multiple container instances.

You need to manage:

- Container failures.
- Application availability.
- Traffic distribution.
- Scaling.
- Application deployments.
- Networking.
- Persistent storage.
- Resource allocation.

Managing all these activities manually becomes difficult.

Kubernetes automates many of these operations.

### Key Kubernetes Components

| Component | Description |
|---|---|
| Cluster | Collection of machines managed by Kubernetes. |
| Control Plane | Manages cluster operations and desired state. |
| Worker Node | Machine that runs application workloads. |
| API Server | Entry point for Kubernetes API requests. |
| etcd | Stores persistent cluster state. |
| Scheduler | Selects suitable nodes for Pods. |
| Controller Manager | Runs controllers that reconcile cluster state. |
| Kubelet | Manages Pods on Worker Nodes. |
| Container Runtime | Executes containers. |
| Kube-proxy | Implements Service networking rules when used. |
| Pod | Smallest deployable unit in Kubernetes. |
| Deployment | Manages stateless application workloads. |
| Service | Provides stable networking for Pods. |

### Kubernetes Architecture

```text
                  Kubernetes Cluster
                          |
             +------------+------------+
             |                         |
             v                         v
        Control Plane              Worker Nodes
             |                         |
       +-----+------+             +----+------+
       |     |      |             |           |
       v     v      v             v           v
      API   etcd Scheduler      Kubelet    Container
    Server                       |         Runtime
       |                         |
       |                         v
       |                     +-------+
       |                     |  Pod  |
       |                     | Nginx |
       |                     +-------+
       |
       +-----------------------------+
```

### Important Kubernetes Commands

```bash
# Check cluster information
kubectl cluster-info

# List nodes
kubectl get nodes

# Create deployment
kubectl create deployment nginx --image=nginx

# List Pods
kubectl get pods

# Scale deployment
kubectl scale deployment nginx --replicas=3

# Expose deployment
kubectl expose deployment nginx --type=NodePort --port=80

# View deployment details
kubectl describe deployment nginx

# Delete deployment
kubectl delete deployment nginx
```

---

## ⚖️ 4. Docker vs Kubernetes – Key Differences

| Feature | Docker | Kubernetes |
|---|---|---|
| Primary Purpose | Containerization | Container orchestration |
| Main Function | Build and run containers | Manage containerized workloads |
| Container Management | Individual containers and applications | Containerized applications across clusters |
| Architecture | Docker Engine-based | Control Plane and Worker Nodes |
| Deployment | Docker CLI and Compose | Kubernetes manifests and APIs |
| Scaling | Manual or externally automated | Supports automatic and manual scaling |
| Self-Healing | Basic restart policies | Controller-driven workload reconciliation |
| Load Balancing | Docker networking and external solutions | Kubernetes Services and ingress traffic solutions |
| Networking | Docker networks | CNI-based Pod networking and Services |
| Storage | Docker volumes and mounts | PV, PVC, StorageClass, CSI |
| Service Discovery | Docker DNS and networking | Kubernetes DNS and Services |
| Rolling Updates | Requires deployment tooling or orchestration | Native Deployment rollout support |
| Configuration | Environment variables and Compose | ConfigMaps and Secrets |
| Scheduling | Docker host-level container execution | Cluster-level Pod scheduling |
| High Availability | Requires additional infrastructure or orchestration | Supports HA cluster and workload configurations |
| Typical Usage | Local development and container runtime | Production workload orchestration |

**Important:** Docker and Kubernetes are not competing technologies. Docker can build container images that Kubernetes runs using a compatible container runtime.

---

## 🏗️ 5. Docker vs Kubernetes Architecture

### Docker Architecture

Docker Engine provides an environment for managing containers on a host.

```text
              Developer
                  |
                  v
             Docker CLI
                  |
                  v
             Docker API
                  |
                  v
             Docker Daemon
                  |
        +---------+---------+
        |         |         |
        v         v         v
      Image    Container  Network
                  |
                  v
             Application
```

### Kubernetes Architecture

Kubernetes manages application workloads across multiple Worker Nodes.

```text
                  Kubernetes
                     |
              Control Plane
                     |
             +-------+-------+
             |               |
             v               v
           Node-1           Node-2
             |               |
         +---+---+       +---+---+
         |       |       |       |
         v       v       v       v
       Pod-1   Pod-2   Pod-3   Pod-4
         |       |       |       |
         +-------+-------+-------+
                     |
                  Service
```

---

## 🔗 6. How Docker and Kubernetes Work Together

Docker and Kubernetes can be used together in a container-based application delivery workflow.

Let's understand with an Nginx application example.

### Step 1: Create Application

Developers write application code.

### Step 2: Create Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

### Step 3: Build Docker Image

```bash
docker build -t nginx-demo:v1 .
```

### Step 4: Run Container Locally

```bash
docker run -d -p 8080:80 nginx-demo:v1
```

### Step 5: Push Image to Container Registry

```bash
docker tag nginx-demo:v1 <registry-name>/nginx-demo:v1

docker push <registry-name>/nginx-demo:v1
```

For example, your registry could be Docker Hub or Azure Container Registry (ACR).

### Step 6: Deploy Application in Kubernetes

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: nginx-demo

spec:
  replicas: 3

  selector:
    matchLabels:
      app: nginx-demo

  template:
    metadata:
      labels:
        app: nginx-demo

    spec:
      containers:
        - name: nginx
          image: <registry-name>/nginx-demo:v1

          ports:
            - containerPort: 80
```

### Step 7: Deploy to Kubernetes

```bash
kubectl apply -f deployment.yaml
```

### Step 8: Verify Deployment

```bash
kubectl get deployments

kubectl get pods -o wide
```

### Step 9: Expose Application

```bash
kubectl expose deployment nginx-demo \
  --type=NodePort \
  --port=80
```

### Step 10: Verify Service

```bash
kubectl get services
```

**Result:** Docker builds and packages the application, while Kubernetes manages its deployment and runtime lifecycle.

---

## 🔄 7. Does Kubernetes Require Docker?

**No. Kubernetes does not require Docker Engine to run containers.**

This is an important interview question.

Earlier Kubernetes supported Docker Engine through an integration called dockershim.

However, dockershim was removed in Kubernetes v1.24.

Modern Kubernetes uses the Container Runtime Interface (CRI) to communicate with container runtimes.

### Supported Container Runtimes

| Runtime | Description |
|---|---|
| containerd | Widely used container runtime. |
| CRI-O | Lightweight Kubernetes-focused container runtime. |

### How Does Kubernetes Run Docker-Built Images?

Docker-built images follow the OCI image format standards and can be consumed by compatible runtimes such as containerd.

Example:

```text
              Dockerfile
                  |
                  v
              Docker Build
                  |
                  v
              OCI Image
                  |
                  v
             Container Registry
                  |
                  v
               Kubernetes
                  |
                  v
               Kubelet
                  |
                  v
                  CRI
                  |
                  v
              containerd
                  |
                  v
             Running Container
```

### Important Difference

- Docker Engine is a container management platform.
- containerd is a container runtime.
- CRI is the interface Kubernetes uses to communicate with container runtimes.
- OCI defines container image and runtime specifications.

**Remember:** Docker is still widely used to build, test, and package container images, even when Kubernetes uses containerd to run them.

---

## 📦 8. Docker Compose vs Kubernetes

Docker Compose and Kubernetes both support multi-container applications, but they target different operational environments and requirements.

| Feature | Docker Compose | Kubernetes |
|---|---|---|
| Primary Use | Multi-container application management | Cluster-level orchestration |
| Configuration | compose.yaml | Kubernetes YAML manifests |
| Deployment | Docker Compose CLI | kubectl / GitOps tools |
| Scaling | Manual scaling | Manual and automatic scaling |
| Networking | Docker networks | Kubernetes Services and CNI |
| Self-Healing | Container restart policies | Workload controllers and reconciliation |
| Environment | Primarily single Docker host | Multi-node cluster |
| Complexity | Relatively simple | More operationally complex |

### Docker Compose Example

```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"

  redis:
    image: redis:alpine
```

Deploy:

```bash
docker compose up -d
```

### Kubernetes Equivalent

Kubernetes generally uses separate resources such as Deployments and Services to define the application workloads and networking.

---

## 🏢 9. Real-World Use Cases

### Docker Use Cases

- Application development.
- Local testing.
- CI/CD image building.
- Application packaging.
- Microservices development.
- Consistent development environments.

### Kubernetes Use Cases

- Production microservices deployments.
- Large-scale application management.
- Automated scaling.
- High-availability workloads.
- Cloud-native applications.
- Multi-node container orchestration.
- GitOps-based deployments.

### Example: Enterprise Application

Imagine an enterprise application containing five microservices:

```text
                  Application
                       |
          +------------+------------+
          |            |            |
          v            v            v
        UI Service  API Service  Auth Service
          |            |            |
          +------------+------------+
                       |
              Kubernetes Cluster
                       |
             +---------+---------+
             |         |         |
             v         v         v
           Node-1    Node-2    Node-3
             |         |         |
            Pods      Pods      Pods
```

Docker is used to build and package each microservice.

Kubernetes deploys, schedules, scales, and manages those microservices.

---

## ☁️ 10. Docker and Kubernetes in Azure

In Microsoft Azure, Docker and Kubernetes are commonly used together with Azure cloud services.

### Azure Container Architecture

| Azure Service | Purpose |
|---|---|
| Azure Container Registry (ACR) | Stores Docker and OCI container images. |
| Azure Kubernetes Service (AKS) | Managed Kubernetes platform. |
| Azure Container Apps | Managed application platform based on container technology. |
| Azure Virtual Machines | Infrastructure for self-managed container environments. |
| Azure Monitor | Monitoring and observability. |
| Microsoft Entra ID | Identity and access management. |

### Example Azure Workflow

```text
              Developer
                  |
                  v
              Docker Build
                  |
                  v
              Docker Image
                  |
                  v
           Azure Container Registry
                  |
                  v
       Azure Kubernetes Service (AKS)
                  |
          +-------+-------+
          |               |
          v               v
        Node-1          Node-2
          |               |
          v               v
        Pods            Pods
          |               |
          +-------+-------+
                  |
                  v
          Azure Load Balancer
                  |
                  v
               Users
```

---

## 🧪 11. Hands-on Practice

Let's perform a practical comparison using Docker and Kubernetes.

### Lab 1: Run Nginx Using Docker

**Step 1: Pull Image**

```bash
docker pull nginx:alpine
```

**Step 2: Run Container**

```bash
docker run -d \
  --name docker-nginx \
  -p 8080:80 \
  nginx:alpine
```

**Step 3: Verify**

```bash
docker ps
```

**Step 4: Test Application**

```bash
curl http://localhost:8080
```

**Step 5: Cleanup**

```bash
docker stop docker-nginx

docker rm docker-nginx
```

### Lab 2: Run Nginx Using Kubernetes

**Step 1: Create Deployment**

```bash
kubectl create deployment nginx \
  --image=nginx:alpine \
  --replicas=3
```

**Step 2: Verify Pods**

```bash
kubectl get pods
```

**Step 3: Expose Application**

```bash
kubectl expose deployment nginx \
  --type=NodePort \
  --port=80
```

**Step 4: Verify Service**

```bash
kubectl get services
```

**Step 5: Scale Deployment**

```bash
kubectl scale deployment nginx --replicas=5
```

**Step 6: Cleanup**

```bash
kubectl delete deployment nginx

kubectl delete service nginx
```

---

## 🎤 12. Interview Questions and Answers

### Q1. What is the main difference between Docker and Kubernetes?

Docker is used to build and run containers, whereas Kubernetes automates the deployment, scaling, and management of containerized workloads.

### Q2. Can Kubernetes work without Docker?

Yes. Kubernetes uses the Container Runtime Interface (CRI) and supports runtimes such as containerd and CRI-O.

### Q3. Does Kubernetes replace Docker?

No. Kubernetes does not replace Docker's image-building and development capabilities. It provides orchestration for containerized workloads.

### Q4. What is the difference between Docker Image and Container?

A Docker Image is a read-only template, while a container is an instantiated, running or stopped execution environment created from an image.

### Q5. What happened to dockershim?

Dockershim was the built-in integration that allowed Kubernetes to use Docker Engine as its container runtime. It was removed in Kubernetes v1.24.

### Q6. What is containerd?

containerd is a container runtime responsible for managing the container lifecycle, including image handling and container execution.

### Q7. What is Docker Compose?

Docker Compose is a tool used to define and manage multi-container applications using a YAML configuration file.

### Q8. What is the difference between Docker Compose and Kubernetes?

Docker Compose primarily manages multi-container applications on a Docker host, while Kubernetes manages workloads across a cluster.

### Q9. Can Kubernetes run Docker-built images?

Yes. Docker-built images compatible with OCI image specifications can run using compatible Kubernetes container runtimes.

### Q10. What is the relationship between Docker, containerd, and Kubernetes?

Docker can build images, Kubernetes communicates with compatible runtimes through CRI, and containerd can execute those images as containers.

---

## 📚 13. Official Documentation

| Technology | Documentation |
|---|---|
| Docker Documentation | https://docs.docker.com/ |
| Docker Architecture | https://docs.docker.com/get-started/docker-overview/ |
| Docker Compose | https://docs.docker.com/compose/ |
| Kubernetes Documentation | https://kubernetes.io/docs/ |
| Kubernetes Container Runtime | https://kubernetes.io/docs/setup/production-environment/container-runtimes/ |
| Container Runtime Interface | https://kubernetes.io/docs/concepts/architecture/cri/ |
| containerd | https://containerd.io/ |
| Open Container Initiative | https://opencontainers.org/ |
| Azure Container Registry | https://learn.microsoft.com/en-us/azure/container-registry/ |
| Azure Kubernetes Service | https://learn.microsoft.com/en-us/azure/aks/ |

---

## 🎯 14. Key Takeaways

| Concept | Remember |
|---|---|
| Docker | Containerization and image-building ecosystem. |
| Kubernetes | Container orchestration platform. |
| Docker Image | Application packaging template. |
| Container | Isolated application execution environment. |
| Dockerfile | Instructions to build an image. |
| Docker Compose | Multi-container application management. |
| containerd | Container runtime. |
| CRI | Interface between Kubernetes and container runtimes. |
| OCI | Container image and runtime standards. |
| AKS | Azure-managed Kubernetes service. |
| ACR | Azure container image registry. |

### Final Understanding

**Docker answers:** How do I package and run my application in a container?

**Kubernetes answers:** How do I deploy, scale, manage, and maintain my containerized applications across a cluster?

Both technologies play an important role in modern DevOps and Cloud-Native engineering.

---

<p align="center">
  <b>🐳 Docker + ☸️ Kubernetes = Cloud-Native Application Platform</b>
  <br/><br/>
  <i>Build with Docker. Orchestrate with Kubernetes. Scale with Confidence.</i>
  <br/><br/>
  <b>Kubernetes-AIO | Learn • Practice • Deploy • Master</b>
</p>