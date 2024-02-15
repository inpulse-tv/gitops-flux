# gitops-flux

Ce dépôt contient les ressources relatives à l'épisode 43 de inpulse.tv 👉 https://youtu.be/r8KANQwLotk

 On y trouve un déploiement de Flux sur cluster Kubernetes local avec Kind.

## FORK ME ⚠️

La première chose à faire est de forker ce répertoire afin de pouvoir committer en toute quiétude.

## Pré-requis 

* 🐧 [Linux]()
* 🐋 [Docker](https://docs.docker.com/get-docker/)

Un token GitHub est aussi nécessaire. Pour en récupérer un, c'est par [ici](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).


## Installation Flux, weave-gitops et localstack 

Lancer le script
```bash
export GITHUB_TOKEN="<your_token>"
./bootstrap.sh
```
Ce script fera plusieurs choses :
* Télécharger les binaires nécessaires dans le sous-dossier `./bin`
* Démarrer un cluster Kubernetes avec Kind
* Bootstrap flux
* Générer les manifests Flux/Kube pour l'installation de localstack et weave gitops

Flux a commité des fichiers automatiquement, récupérons les
```bash 
git pull 
```

Les fichiers de base d'une installation flux sont situés dans le dossier `clusters/kind/flux-system`. Le fichier important est `gotk-sync.yml` car il contient deux entités :
* le `GitRepository` qui contient la configuration de la synchronisation de ce répertoire git.
* le `Kustomization` qui contient la configuration qui va continuellement appliquer les fichiers kube dans le dossier `clusters/kind`. Ce dossier est le point de départ pour y ajouter les fichiers de configuration de nos applications.

Trois fichiers ont été générés par le script bash contenant 4 manifestes flux/kube :

* le `HelmRepository` des applications de weave-gitops et localstack
* le `HelmRelease` de weave-gitops
* le `Kustomization` qui contient la configuration qui va continuellement appliquer les fichiers kube dans le dossier `apps`. Ce dossier est dédié à y déployer les applications métiers. Ici notre application est `localstack`. Dans ce dossier, il n'y a donc que le `HelmRelease` de localstack

> Pour plus d'infos sur Helm [ici](https://helm.sh/docs/intro/using_helm/#three-big-concepts)

On peut commiter l'ensemble des fichiers pour déployer localstack et weave-gitops

```bash
git add . && \
git commit -m "Add localstack helm repo & release and track kustomization file under apps folder" && \
git push
```

Weave-gitops est un dashboard que l'on peut utiliser pour voir l'ensemble des réconciliations flux qui se produisent. Pour accéder à cette interface c'est par ici http://localhost:9001 (utilisateur admin, mot de passe admin). On va pouvoir visualiser l'ensemble des réconciliations en cours. 

## Installation tf-controller

Lancer le script
```bash
./bootstrap-tf.sh
```
Ce script va :
* Installer tfctl CLI
* Générer les manifests Kube pour l'installation du tf-controller

```bash
git add . && \
git commit -m "Install `tf-controller` from helm and watch terraform resources" && \
git push && \
flux get kustomizations --watch
```

On a déployé le `tf-controller` à partir de Helm et donc deux nouveaux fichiers qui sont apparus, le `HelmRepository` et le `HelmRelease` du `tf-controller`. 

De plus, on a aussi commencé à regarder continuellement les fichiers Kube/flux dans `tf/flux` qui contient un fichier de configuration du `tf-controller`. Et donc, maintenant le `tf-controller` va appliquer les fichiers terraform qui sont dans le dossier `./tf`. 

Vous pouvez vous rendre sur http://localhost:3000/aws qui affichera un schéma des ressources AWS créées sur localstack, vous devriez voir un VPC, deux sous-réseaux et une machine virtuelle (Il y a aussi un VPC et des sous-réseaux qui sont créés par défaut).

## Modification de l'infra terraform

Nous allons maintenant modifier nos fichiers terraform et créer une pull request à partir de celles-ci. Si vous êtes familier avec terraform, modifiez le fichier `./tf/main.tf` à votre guise. Sinon, ajoutez le bloc ci-dessous au fichier  

``` 
resource "aws_instance" "app_server_b" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.subnet_b.id
}
```
Maintenant poussons la modification 

```bash
git add ./tf/main.tf && \
git commit -m "Add aws resources to localstack" && \
git push
```

Normalement la sortie de la commande push vous donne un lien pour créer la pull request. Une fois sur GitHub, vous pouvez cliquer sur "Create Pull Request". 

Après un moment, le temps de laisser le `tf-controller` prendre en compte cette pull request, un commentaire devrait apparaître sur la pull request affichant les changements voulus par la pull request, ici si vous avez copié le bloc ci-dessus, ce sera une nouvelle instance.

Maintenant vous pouvez merger la pull request, le `tf-controller` va prendre le relais pour appliquer le fichier et créer les ressources que vous avez ajoutées au fichier terraform. Retournez sur http://localhost:3000/aws, votre changement a été pris en compte.