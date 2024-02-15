#!/bin/bash

. ./common.sh

flux_version="2.2.3"
kind_version="v0.21.0"
gitops_version="v0.38.0"
github_repository=$(git remote get-url origin | cut -d ':' -f2)
owner=$(git remote get-url origin | cut -d ':' -f2 | cut -d'/' -f1)

mkdir -p ./bin ./apps ./clusters/kind

echo_green "Download flux, kind, gitops & kubectl"
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

curl --silent --location "https://github.com/weaveworks/weave-gitops/releases/download/${gitops_version}/gitops-$(uname)-$(uname -m).tar.gz" | tar xz -C /tmp
mv /tmp/gitops ./bin
./bin/gitops version

echo_green "Create k8s cluster"
./bin/kind create cluster --name=gitops-flux --config=kind-config.yaml

set -e
./bin/flux  check --pre

echo_green "Bootstrap flux and commit to github"
./bin/flux  bootstrap github \
  --owner=${owner} \
  --repository=gitops-flux \
  --branch=main \
  --path=./clusters/kind \
  --personal

echo_green "Export Weave gitops dashboard"
./bin/gitops create dashboard ww-gitops \
  --password=admin \
  --values="./values-gitops-dahsboard.yml" \
  --export > ./clusters/kind/helm-weave-gitops-dashboard.yaml

echo_green "Export kustomization apps"
./bin/flux create kustomization apps \
  --namespace=flux-system \
  --source=GitRepository/flux-system.flux-system \
  --path="./apps" \
  --prune=true \
  --wait=true \
  --verbose \
  --interval=1m \
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
  --interval=1m \
  --source=HelmRepository/localstack.flux-system \
  --values="./values-localstack.yml" \
  --export > ./apps/helm-release-localstack.yaml

echo_green "Running cloud view"
docker run -d -p 3000:3000 ghcr.io/laupse/cloud-view:v0.1.0 --localstack --localstack-host host.docker.internal:4566
