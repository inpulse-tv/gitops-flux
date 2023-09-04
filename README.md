# gitops-flux

``` bash
export GITHUB_TOKEN="<your_token>"
./bootstrap.sh
git pull
git add . && git commit -m "Add localstack helm repo & release and track kustomization file under apps folder" 
git push
flux get kustomizations --watch
./bootstrap-tf.sh
git add . && git commit -m "Install tf-controller from helm and watch terraform ressources"
git push
flux get kustomizations --watch

```