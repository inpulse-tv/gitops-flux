#!/bin/bash

. ./common.sh

tfctl_version="v0.16.0-rc.2"
tfctl_download_url="https://github.com/weaveworks/tf-controller/releases/download"

mkdir -p bin

# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./tfctl.tar.gz ${tfctl_download_url}/${tfctl_version}/tfctl_Linux_amd64.tar.gz
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./tfctl.tar.gz ${tfctl_download_url}/${tfctl_version}/tfctl_Linux_arm64.tar.gz
tar -xzf ./tfctl.tar.gz tfctl
mv ./tfctl ./bin/tfctl
rm tfctl.tar.gz

echo_green "Export helmrepository source tf-controller"
./bin/flux create source helm tf-controller \
  --url=https://weaveworks.github.io/tf-controller/ \
  --verbose \
  --interval=10m \
  --export > ./clusters/kind/localstack-helm-repo.yaml

echo_green "Export helmrelease tf-controller "
./bin/flux create helmrelease localstack \
  --chart=localstack \
  --values="branchPlanner.enabled=true" \
  --verbose \
  --interval=30s \
  --source=HelmRepository/tf-controller.flux-system \
  --export > ./apps/localstack-helm-release.yaml

echo_green "Export terraform ressources "
./bin/tfctl create tf-ressources \
  --verbose \
  --interval=30s \
  --source=GitRepository/flux-system.flux-system \
  --path=".tf" \
  --approve-plan="auto" \
  --export > ./tf/flux/localstack-helm-release.yaml

echo_green "Export kustomization localstack"
./bin/flux create kustomization localstack \
  --target-namespace=default \
  --source=GitRepository/flux-system.flux-system \
  --path="./tf/flux" \
  --prune=true \
  --wait=true \
  --verbose \
  --interval=30m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --export > ./clusters/kind/localstack-kustomization.yaml