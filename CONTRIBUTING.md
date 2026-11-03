# 🤝 Contributing to Kubernetes-AIO

Thank you for your interest in contributing to **Kubernetes-AIO**!

Kubernetes-AIO is an open-source, hands-on learning repository focused on Kubernetes fundamentals, advanced concepts, cloud-native technologies, and real-world implementation scenarios.

We welcome contributions from Kubernetes enthusiasts, DevOps engineers, Cloud engineers, Platform engineers, and developers.

Our goal is to make Kubernetes learning practical, structured, and accessible to everyone.

## 🎯 How Can You Contribute?

You can contribute in several ways:

- Add new Kubernetes concepts and tutorials.
- Improve existing documentation.
- Add practical Kubernetes YAML manifests.
- Share real-world implementation scenarios.
- Add troubleshooting guides and solutions.
- Fix incorrect configurations or commands.
- Improve architecture diagrams.
- Add Azure Kubernetes Service (AKS) examples.
- Improve Helm charts and templates.
- Add monitoring and security examples.

## 📂 Contribution Guidelines

Please follow the existing repository structure when adding new content.

Every contribution should:

1. Be relevant to Kubernetes or cloud-native technologies.
2. Include clear explanations.
3. Follow Kubernetes YAML best practices.
4. Include practical examples wherever possible.
5. Use meaningful filenames and folder names.
6. Be tested before submission.
7. Include relevant documentation and verification steps.

## 🚀 How to Contribute

### Step 1: Fork the Repository

Fork the Kubernetes-AIO repository to your GitHub account.

### Step 2: Clone Your Fork

```bash
git clone https://github.com/<YOUR-USERNAME>/Kubernetes-AIO.git

cd Kubernetes-AIO
```

### Step 3: Create a New Branch

```bash
git checkout -b feature/add-kubernetes-example
```

### Step 4: Make Your Changes

Add your documentation, YAML manifests, examples, or improvements.

### Step 5: Validate Your Changes

For Kubernetes YAML manifests, validate the configuration before submitting.

```bash
kubectl apply --dry-run=client -f deployment.yaml

kubectl diff -f deployment.yaml
```

For Helm charts:

```bash
helm lint ./sample-chart

helm template sample-release ./sample-chart
```

### Step 6: Commit Your Changes

```bash
git add .

git commit -m "feat: add Kubernetes deployment examples"
```

### Step 7: Push Your Branch

```bash
git push origin feature/add-kubernetes-example
```

### Step 8: Create a Pull Request

Open a Pull Request against the main branch of the original repository.

Include:

- What you changed.
- Why the change is useful.
- Which Kubernetes concepts are covered.
- Testing and validation performed.
- Screenshots or command outputs, if applicable.

## 📝 Documentation Standards

When adding a new tutorial, follow this suggested structure:

```text
# Topic Name

## Overview

Explain the Kubernetes concept.

## Architecture

Describe how the components work.

## Prerequisites

List the required tools and configurations.

## Implementation

Provide step-by-step instructions.

## YAML Manifests

Include working Kubernetes YAML examples.

## Verification

Explain how to validate the implementation.

## Troubleshooting

Document common errors and solutions.

## Cleanup

Provide commands to remove created resources.
```

## 🌿 Commit Message Guidelines

Use clear and meaningful commit messages.

| Prefix | Purpose |
|---|---|
| feat | Add a new feature or tutorial |
| fix | Fix an existing issue |
| docs | Update documentation |
| refactor | Improve existing structure |
| test | Add validation or testing |
| chore | Maintenance changes |

Examples:

```bash
git commit -m "feat: add persistent volume examples"

git commit -m "docs: update AKS networking guide"

git commit -m "fix: correct deployment manifest"
```

## 🔍 Pull Request Checklist

Before submitting your Pull Request, make sure:

- [ ] Changes follow the repository structure.
- [ ] Documentation is clear and readable.
- [ ] YAML manifests are properly formatted.
- [ ] Kubernetes configurations are validated.
- [ ] Commands and examples are tested.
- [ ] No credentials, passwords, or secrets are committed.
- [ ] Commit messages are meaningful.
- [ ] Pull Request description explains the changes.

## 🔐 Security Guidelines

Never commit:

- Kubernetes Secret values containing real credentials.
- Azure service principal credentials.
- API keys or access tokens.
- Private SSH keys.
- Production connection strings.
- Sensitive infrastructure configuration.

Always use placeholders or example values in documentation.

## 📜 Code of Conduct

All contributors are expected to maintain a respectful, professional, and collaborative environment.

Be constructive, respect different experience levels, and help others learn.

## ⭐ Support the Project

If you find Kubernetes-AIO useful:

- Give the repository a ⭐ Star.
- Share it with other Kubernetes learners.
- Report issues and suggest improvements.
- Contribute practical examples.

## 📄 License

By contributing to this repository, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

**Thank you for helping make Kubernetes-AIO better!**

Happy Learning & Happy Contributing! ☸️🚀