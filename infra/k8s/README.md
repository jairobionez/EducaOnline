Kubernetes manifests templates

This folder contains template manifests for deploying backend services and the frontend locally (Minikube) or on a cluster.

Usage:
- Replace `REPLACE_IMAGE` with your built image (e.g. `myregistry/servicename:tag`).
- Adjust `replicas`, `resources`, and `envFrom` to match your environment.
- Ensure each API exposes a health endpoint (`/health` or `/health/ready`) for probes or update the probe paths.

Quick Minikube usage:

- Use the provided PowerShell helper to build/load images and apply manifests: `infra/k8s/deploy-minikube.ps1`.
- Or manually:
	- Start Minikube: `minikube start --driver=docker`
	- Build images and load into Minikube (or use `minikube image load`)
	- Apply manifests with kustomize: `kubectl apply -k infra/k8s`
