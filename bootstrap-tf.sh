#!/bin/bash

. ./common.sh

tfctl_version="v0.16.0-rc.2"
tfctl_download_url="https://github.com/weaveworks/tf-controller/releases/download"

mkdir -p ./bin ./apps/ ./tf/flux

echo_green "Download tfctl"
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -sLo ./tfctl.tar.gz ${tfctl_download_url}/${tfctl_version}/tfctl_Linux_amd64.tar.gz
# For ARM64
[ $(uname -m) = aarch64 ] && curl -sLo ./tfctl.tar.gz ${tfctl_download_url}/${tfctl_version}/tfctl_Linux_arm64.tar.gz
tar -xzf ./tfctl.tar.gz tfctl
mv ./tfctl ./bin/tfctl
rm tfctl.tar.gz

kubectl create secret generic branch-planner-token \
    --namespace=flux-system \
    --from-literal="token=${GITHUB_TOKEN}"

set -e
echo_green "Export helmrepository source tf-controller"
./bin/flux create source helm tf-controller \
  --url=https://weaveworks.github.io/tf-controller/ \
  --verbose \
  --interval=10m \
  --export > ./clusters/kind/helm-repo-tf-controller.yaml

echo_green "Export helmrelease tf-controller"
cat <<EOF > values-tf-controller.yml
branchPlanner:
  enabled: true
EOF

./bin/flux create helmrelease tf-controller \
  --namespace=flux-system \
  --chart=tf-controller \
  --values="values-tf-controller.yml" \
  --verbose \
  --interval=1m \
  --source=HelmRepository/tf-controller.flux-system \
  --chart-version="v0.16.0-rc.2" \
  --export > ./apps/helm-release-tf-controller.yaml
rm values-tf-controller.yml

echo_green "Export kustomization tf-ressources"
./bin/flux create kustomization tf-ressources \
  --namespace=default \
  --source=GitRepository/flux-system.flux-system \
  --path="./tf/flux" \
  --prune=true \
  --wait=true \
  --verbose \
  --interval=1m \
  --retry-interval=2m \
  --health-check-timeout=3m \
  --export > ./clusters/kind/kustomization-tf-ressources.yaml
