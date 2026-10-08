# Helm Chart README – Multi-Environment Deployment (Dev, QA, Staging, Prod)

````md
# Helm Chart - Nginx Multi-Environment Deployment

## Overview

This repository contains a reusable **Helm Chart** for deploying an **Nginx** application on Kubernetes.

Instead of maintaining separate Kubernetes manifests for every environment (Development, QA, Staging, Production), this chart follows the **Helm Best Practice**:

- Single reusable chart
- Multiple environment-specific `values.yaml` files
- Same templates
- Different configurations

This approach makes deployments consistent, easier to maintain, and less error-prone.

---

# Problem Statement

Imagine your company has an application running in four different environments.

```
Development
QA
Staging
Production
```

Although the application is the same, each environment requires different configurations.

For example:

| Configuration | Dev | QA | Staging | Production |
|---------------|-----|----|----------|------------|
| Replicas | 1 | 2 | 3 | 5 |
| Image Tag | latest | qa-v1 | rc-v1 | v1.0.0 |
| CPU | 100m | 200m | 300m | 500m |
| Memory | 128Mi | 256Mi | 512Mi | 1Gi |

Without Helm, you would have to maintain four different Deployment YAML files.

Example:

```
deployment-dev.yaml
deployment-qa.yaml
deployment-staging.yaml
deployment-prod.yaml
```

If you wanted to change something simple like:

```
containerPort: 80 → 8080
```

You would have to update all four files.

This becomes difficult to manage as applications grow.

---

# Solution

Helm solves this problem by separating:

- Kubernetes Templates
- Configuration Values

The Deployment YAML remains the same.

Only the values change for each environment.

```
                Helm Chart

             templates/
                 │
        deployment.yaml
                 │
        service.yaml
                 │
        ingress.yaml

                 ▲
                 │

    values-dev.yaml
    values-qa.yaml
    values-staging.yaml
    values-prod.yaml
```

Helm injects the appropriate values during deployment.

---

# Repository Structure

```
nginx-chart/

│
├── Chart.yaml
├── values.yaml
│
├── values-dev.yaml
├── values-qa.yaml
├── values-staging.yaml
├── values-prod.yaml
│
└── templates
      ├── deployment.yaml
      ├── service.yaml
      └── ingress.yaml
```

---

# Deployment Template

Instead of hardcoding values, Helm templates use placeholders.

Example:

```yaml
replicas: {{ .Values.replicaCount }}

image:
  repository: {{ .Values.image.repository }}
  tag: {{ .Values.image.tag }}

containerPort: {{ .Values.containerPort }}

resources:
  limits:
    cpu: {{ .Values.resources.limits.cpu }}
    memory: {{ .Values.resources.limits.memory }}
```

Helm replaces these placeholders using the selected values file.

---

# Example values-dev.yaml

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: latest
  pullPolicy: IfNotPresent

containerPort: 80

resources:
  limits:
    cpu: 200m
    memory: 256Mi

  requests:
    cpu: 100m
    memory: 128Mi
```

---

# Example values-qa.yaml

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: qa-v1
  pullPolicy: IfNotPresent

containerPort: 80

resources:
  limits:
    cpu: 300m
    memory: 512Mi

  requests:
    cpu: 200m
    memory: 256Mi
```

---

# Example values-staging.yaml

```yaml
replicaCount: 3

image:
  repository: nginx
  tag: rc-v1
  pullPolicy: IfNotPresent

containerPort: 80

resources:
  limits:
    cpu: 500m
    memory: 768Mi

  requests:
    cpu: 300m
    memory: 512Mi
```

---

# Example values-prod.yaml

```yaml
replicaCount: 5

image:
  repository: nginx
  tag: v1.0.0
  pullPolicy: IfNotPresent

containerPort: 80

resources:
  limits:
    cpu: "1"
    memory: 1Gi

  requests:
    cpu: 500m
    memory: 512Mi
```

---

# How Helm Uses These Files

Suppose we deploy the Dev environment.

Command:

```bash
helm install nginx-dev . \
-f values-dev.yaml
```

Helm internally renders:

```yaml
replicas: 1

image:
  repository: nginx
  tag: latest
```

Now deploy QA.

```bash
helm install nginx-qa . \
-f values-qa.yaml
```

Generated Deployment becomes:

```yaml
replicas: 2

image:
  repository: nginx
  tag: qa-v1
```

The template never changes.

Only the values file changes.

---

# Real World Deployment Flow

```
                 Git Repository

              Helm Chart
                  │
                  │
        deployment.yaml
                  │
                  ▼
         +------------------+
         | values-dev.yaml  |
         +------------------+
                  │
          helm install
                  │
                  ▼
           Dev Kubernetes

---------------------------------------

         +------------------+
         | values-qa.yaml   |
         +------------------+
                  │
          helm install
                  │
                  ▼
            QA Kubernetes

---------------------------------------

      +-----------------------+
      | values-staging.yaml   |
      +-----------------------+
                  │
          helm install
                  │
                  ▼
        Staging Kubernetes

---------------------------------------

        +--------------------+
        | values-prod.yaml   |
        +--------------------+
                  │
          helm install
                  │
                  ▼
       Production Kubernetes
```

---

# Release Names

Notice that every deployment has a different release name.

```
Development

Release Name:
nginx-dev

Deployment:
nginx-dev-deployment
```

```
QA

Release Name:
nginx-qa

Deployment:
nginx-qa-deployment
```

```
Production

Release Name:
nginx-prod

Deployment:
nginx-prod-deployment
```

This happens because of:

```yaml
metadata:
  name: {{ .Release.Name }}-deployment
```

---

# Chart Name

Container labels use:

```yaml
{{ .Chart.Name }}
```

If Chart.yaml contains

```yaml
name: nginx-chart
```

Then labels become

```yaml
labels:
  app: nginx-chart
```

---

# Commands

## Validate Template

```bash
helm template nginx-dev . \
-f values-dev.yaml
```

---

## Install Dev

```bash
helm install nginx-dev . \
-f values-dev.yaml
```

---

## Install QA

```bash
helm install nginx-qa . \
-f values-qa.yaml
```

---

## Install Staging

```bash
helm install nginx-staging . \
-f values-staging.yaml
```

---

## Install Production

```bash
helm install nginx-prod . \
-f values-prod.yaml
```

---

## Upgrade Dev

```bash
helm upgrade nginx-dev . \
-f values-dev.yaml
```

---

## Upgrade QA

```bash
helm upgrade nginx-qa . \
-f values-qa.yaml
```

---

## Upgrade Production

```bash
helm upgrade nginx-prod . \
-f values-prod.yaml
```

---

## List Releases

```bash
helm list
```

---

## View Release Values

```bash
helm get values nginx-dev

helm get values nginx-prod
```

---

## View Rendered Manifest

```bash
helm get manifest nginx-prod
```

---

## Rollback

View history

```bash
helm history nginx-prod
```

Rollback

```bash
helm rollback nginx-prod 1
```

---

## Uninstall

```bash
helm uninstall nginx-dev

helm uninstall nginx-qa

helm uninstall nginx-staging

helm uninstall nginx-prod
```

---

# Benefits of This Approach

- Single reusable Helm Chart
- Environment-specific configuration
- No duplicate YAML files
- Easier upgrades
- Easier rollbacks
- Consistent deployments
- Better GitOps compatibility
- Supports CI/CD pipelines
- Easy maintenance
- Production-ready structure

---

# Real-World Example

Consider an e-commerce application.

```
my-ecommerce-chart

        │
        ├──────── dev-release
        │          Replicas = 1
        │          Image = latest
        │
        ├──────── qa-release
        │          Replicas = 2
        │          Image = qa-v1
        │
        ├──────── staging-release
        │          Replicas = 3
        │          Image = rc-v1
        │
        └──────── prod-release
                   Replicas = 10
                   Image = v1.0.0
```

All four deployments use the **same Helm chart**, but each environment has its own configuration through a dedicated values file.

---

# Key Takeaways

- **Templates** define the Kubernetes resources.
- **values.yaml** stores configurable parameters.
- **Environment-specific values files** override defaults.
- **Release Name (`.Release.Name`)** creates unique resource names.
- **Chart Name (`.Chart.Name`)** provides consistent labels.
- One chart can manage multiple environments without duplicating YAML files, making deployments scalable and maintainable.
````

This README is suitable for GitHub and also serves as interview-quality documentation explaining not just *how* Helm works, but *why* this multi-environment pattern is used in real-world DevOps and GitOps workflows.
