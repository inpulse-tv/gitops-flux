#!/bin/bash

. ./common.sh

flux_version="2.0.1"
kind_version="v0.20.0"

echo_green "Download flux and kind cli"
mkdir -p ./bin

# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -sLo ./kind https://kind.sigs.k8s.io/dl/${kind_version}/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -sLo ./kind https://kind.sigs.k8s.io/dl/${kind_version}/kind-linux-arm64
chmod +x ./kind
mv ./kind ./bin

curl -s https://fluxcd.io/install.sh | FLUX_VERSION=${flux_version} bash -s ./bin

./bin/kind create cluster --name gitops-flux

set -e
./bin/flux  check --pre
./bin/flux  install

github_repository=$(git remote get-url origin | cut -d ':' -f2)
owner=$(git remote get-url origin | cut -d ':' -f2 | cut -d'/' -f1)

mkdir -p apps clusters/kind

echo_green "Bootstrap flux and commit to github"
./bin/flux  bootstrap github \
  --owner=${owner} \
  --repository=gitops-flux \
  --branch=main \
  --path=./clusters/kind \
  --personal

git pull origin main

echo_green "Export helmrepository source localstack"
./bin/flux create source helm localstack \
  --url=https://localstack.github.io/helm-charts \
  --verbose \
  --interval=10m \
  --export > ./clusters/kind/localstack-helm-repo.yaml

echo_green "Export helmrelease localstack"
./bin/flux create helmrelease localstack \
  --chart=localstack \
  --verbose \
  --interval=30s \
  --source=HelmRepository/localstack.flux-system \
  --export > ./apps/localstack-helm-release.yaml

echo_green "Export kustomization localstack"
./bin/flux create kustomization localstack \
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
