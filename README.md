# gitops-flux

Ce dépôt contient les ressources relatives à l'épisode XX de inpulse.tv 👉 
On y trouve un déploimeent de flux sur cluster Kubernetes local avec kind

## FORK ME ⚠️

La premiere chose à faire est de forker ce répertoire afin de pouvoir commit en toute quiétude

## Pré-requis 

* 🐧 [Linux]()
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
* Démarrer un custer kubernetes avec Kind
* Bootstrap flux
* Générer les manifests Flux/Kube pour l'installation de localstack et weave gitops

Le bootstrap de flux a commité les fichier de flux et donc s'autosurveiller. Ensuite on peut commiter l'ensemble des fichiers pour déployer localstack et weave-gitops

```bash 
git pull && \
git add . && \
git commit -m "Add localstack helm repo & release and track kustomization file under apps folder" && \
git push
```

Weave-gitops vient avec un dashboard que l'on peut utiliser pour voir l'ensemble des réconciliation flux qui se produisent. On peut aller sur http://localhost:9001 (utilisateur admin, password admin) et lister l'ensemble de réconciliation en cours

## Installation tf-controller

Lancer le script
``` bash
./bootstrap-tf.sh
```
Ce script va :
* Installer tfctl CLI
* Générer les manifests Kube pour l'installation du tf-controller

``` bash
git add . && \
git commit -m "Install tf-controller from helm and watch terraform ressources" && \
git push && \
flux get kustomizations --watch
```

A partir de maintenant le tf-controller va appliquer les fichiers terraform qui sont dans le dossier `./tf`. Vous pouvez vous rendre sur http://localhost:3000/aws qui affichera un schema des ressources aws créer sur localstack, vous devriez voir un vpc deux subnets et une machine viruelle

## Modification l'infra terraform

Nous allons maintenant modifier nos fichier terraform et créer une pull request à partir de celles-ci. Si vous etes familier avec terraform modifier le fichier `./tf/main.tf` à votre guise. Si non, ajouter on peut ajouter le bloc ci-dessous au fichier  

``` 
resource "aws_instance" "app_server_b" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet_b.id
}
```
Maintenant poussons la modification 

``` bash
git add ./tf/main.tf && \
git commit -m "Add aws ressources to localstack" && \
git push
```

Normalement la sortie de la commande push, vous donne un lien pour créer la pull request. Une fois sur github, vous pouvez cliquer sur "Create Pull Request". Après un moment, le temps de laisser le tf-controller prendre en compte cette pull request, un commentaire devrait apparaitre sur la pull request affichant les changements voulu par la pull request, ici si vous avez copier le bloc ci-dessus, ce sera une nouvel instance

Maintenant vous pouvez merger la pull request, le tf-controller va prendre le relais pour appliquer le fichier et créer les ressources que vous avez ajouté au fichier terraform. Retourné sur http://localhost:3000/aws