# gitops-flux

Ce dépôt contient les ressources relatives à l'épisode XX de inpulse.tv 👉 
On y trouve un déploimeent de flux sur cluster Kubernetes local avec kind

## FORK ME ⚠️

La premiere chose à faire est de forker ce répertoire afin de pouvoir commit en toute quiétude

## Pré-requis 

* 🐋 [Docker](https://docs.docker.com/get-docker/)

Un token github est aussi nécessaire. Pour en récupérer un, c'est par [ici](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)


## Installation Flux, weave-gitops et localstack 

Lancer le script
``` bash
export GITHUB_TOKEN="<your_token>"
./bootstrap.sh
```
Ce script fera plusieurs chose :
* Télécharger les binaires nécessaires dans le sous-dossier `./bin`
* Démarrer un custer kubernetes avec Kube
* Bootstrap flux
* Générer les manifests Kube pour l'installation de localstack et weave gitops

Le bootstrap de flux a commité les fichier de fluxs et donc s'autosurveiller. Ensuite on peut commiter l'ensemble des fichiers pour déployer localstack et weave-gitops

```bash 
git pull && \
git add . && \
git commit -m "Add localstack helm repo & release and track kustomization file under apps folder" && \
git push
```

On peut aller sur http://localhost:9001 (utilisateur admin, password admin) et lister l'ensemble de réconciliation en cours


```
git pull
git add . && git commit -m "Add localstack helm repo & release and track kustomization file under apps folder" 
git push
flux get kustomizations --watch
./bootstrap-tf.sh
git add . && git commit -m "Install tf-controller from helm and watch terraform ressources"
git push
flux get kustomizations --watch

```