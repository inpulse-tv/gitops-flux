#!/bin/bash
flux_version="2.0.1"
kind_version="v0.20.0"

GREEN='\033[0;32m'
NC='\033[0m' # No Color

function echo_green {
  printf "${GREEN}${1}${NC}\n"
}


# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/${kind_version}/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/${kind_version}/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

curl -s https://fluxcd.io/install.sh | FLUX_VERSION=${flux_version} sudo bash

kind create cluster --name gitops-flux

flux check --pre
flux install

set -e
github_repository=$(git remote get-url origin | cut -d ':' -f2)
owner=$(git remote get-url origin | cut -d ':' -f2 | cut -d'/' -f1)

echo_green "Bootstrap flux and commit to github"
flux bootstrap github \
  --owner=${owner} \
  --repository=gitops-flux \
  --branch=main \
  --path=./clusters/kind \
  --personal

git pull origin main

echo_green "Export helmrepository source localstack"
flux create source helm localstack \
  --url=https://localstack.github.io/helm-charts \
  --verbose \
  --interval=10m \
  --export > ./clusters/kind/localstack-helm-repo.yaml

echo_green "Export localstack helmrelease"
flux create helmrelease localstack \
  --chart=localstack \
  --verbose \
  --interval=30s \
  --source=HelmRepository/localstack.flux-system \
  --export > ./apps/localstack-helm-release.yaml

echo_green "Export kustomization localstack"
flux create kustomization localstack \
  --target-namespace=default \
  --source=GitRepository/flux-system.flux-system \
  --path="./apps" \
  --prune=true \
  --wait=true \
  --verbose \
  --interval=30m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --export > ./clusters/kind/localstack-kustomization.yaml
