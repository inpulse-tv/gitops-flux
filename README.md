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

Flux a commité des fichiers automatiquemment, récupérons les
``` bash 
git pull 
```

Les fichiers de base d'une installation flux sont  siuté dans le dossier `clusters/kind/flux-system`. Le fichier important est `gotk-sync.yml` car il contient deux entités :
* le `GitRepository` qui contient la configuration de la synchronisatiuon de ce repertoire git.
* le `Kustomization` qui contien la configuration qui va continullement appliquer les fichier kube dans le dossier `clusters/kind`. Ce dossier est le point de départ pour y ajouter les fichiers de configuration de nos applications.

Trois fichiers ont été généré par le script bash contenant 4 manifestes flux/kube :

* le `HelmRepository`des applications de weave-gitops et localstack
* le `HelmRelease` de weave-gitops
* le `Kustomization` qui contient la configuration qui va continuellement appliquer les fichier kube dans le dossier `apps`. Ce dossier est dédié à y déployer les applications métiers. Ici notre application est `localstack`. Dans ce dossier, il n'y donc que le `HelmRelease` de localstack

> Pour plusieurs d'infos sur Helm [ici](https://helm.sh/docs/intro/using_helm/#three-big-concepts)

On peut commiter l'ensemble des fichiers pour déployer localstack et weave-gitops

``` bash
git add . && \
git commit -m "Add localstack helm repo & release and track kustomization file under apps folder" && \
git push
```

Weave-gitops est un dashboard que l'on peut utiliser pour voir l'ensemble des réconciliation flux qui se produisent. Pour accéder à cette interface c'est par ici http://localhost:9001 (utilisateur admin, password admin). On va pouvoir visualiser l'ensemble des réconciliations en cours. 

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
git commit -m "Install `tf-controller` from helm and watch terraform ressources" && \
git push && \
flux get kustomizations --watch
```

On a déployé le `tf-controller` à partir de Helm et donc deux nouveux fichiers qui sont apparu, le `HelmRepository` et le `HelmRelease` du `tf-controller`. 

De plus, on a aussi commencé à regardé continuellement les fichier Kube/flux dans `tf/flux` qui contient un fichier de configuration du `tf-controller`. Et donc, maintenant le `tf-controller` va appliquer les fichiers terraform qui sont dans le dossier `./tf`. V

Vous pouvez vous rendre sur http://localhost:3000/aws qui affichera un schema des ressources aws créer sur localstack, vous devriez voir un vpc deux subnets et une machine viruelle (Il ya aussi un vpc et des subnets qui sont créer par défaut)

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

Normalement la sortie de la commande push, vous donne un lien pour créer la pull request. Une fois sur github, vous pouvez cliquer sur "Create Pull Request". 

Après un moment, le temps de laisser le `tf-controller` prendre en compte cette pull request, un commentaire devrait apparaitre sur la pull request affichant les changements voulu par la pull request, ici si vous avez copier le bloc ci-dessus, ce sera une nouvel instance

Maintenant vous pouvez merger la pull request, le `tf-controller` va prendre le relais pour appliquer le fichier et créer les ressources que vous avez ajouté au fichier terraform. Retourné sur http://localhost:3000/aws, votre changement a été pris en compte.