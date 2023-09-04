#!/bin/bash

. ./common.sh

flux_version="2.0.1"
kind_version="v0.20.0"
github_repository=$(git remote get-url origin | cut -d ':' -f2)
owner=$(git remote get-url origin | cut -d ':' -f2 | cut -d'/' -f1)

mkdir -p ./bin ./apps ./clusters/kind

echo_green "Download flux, kind & kubectl"
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -sLo ./bin/kind https://kind.sigs.k8s.io/dl/${kind_version}/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -sLo ./bin/kind https://kind.sigs.k8s.io/dl/${kind_version}/kind-linux-arm64
chmod +x ./bin/kind

curl -s https://fluxcd.io/install.sh | FLUX_VERSION=${flux_version} bash -s ./bin

# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] &&  curl -sLo ./bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# For ARM64
[ $(uname -m) = aarch64 ] && curl -sLo ./bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
chmod +x ./bin/kubectl

echo_green "Create k8s cluster"
./bin/kind create cluster --name gitops-flux

set -e
./bin/flux  check --pre

echo_green "Bootstrap flux and commit to github"
./bin/flux  bootstrap github \
  --owner=${owner} \
  --repository=gitops-flux \
  --branch=main \
  --path=./clusters/kind \
  --personal
  
echo_green "Export kustomization apps"
./bin/flux create kustomization apps \
  --namespace=flux-system \
  --source=GitRepository/flux-system.flux-system \
  --path="./apps" \
  --prune=true \
  --wait=true \
  --verbose \
  --interval=5m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --export > ./clusters/kind/kustomization-apps.yaml

echo_green "Export helmrepository source localstack"
./bin/flux create source helm localstack \
  --url=https://localstack.github.io/helm-charts \
  --verbose \
  --interval=10m \
  --export > ./clusters/kind/helm-repo-localstack.yaml

echo_green "Export helmrelease localstack"
./bin/flux create helmrelease localstack \
  --namespace=default \
  --chart=localstack \
  --verbose \
  --interval=30s \
  --source=HelmRepository/localstack.flux-system \
  --export > ./apps/helm-release-localstack.yaml

