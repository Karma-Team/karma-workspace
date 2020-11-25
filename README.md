# Workspace Eclipse pour la cross-compilation pour Raspberry Pi

Ce dépôt a pour but d'accueillir le workspace Eclipse, en plaçant les différentes librairies et permettre la cross-compilation à l'aide d'un Docker

## Installation

### Prérequis
Il est nécessaire d'avoir Docker installé, et de pouvoir l'appeler avec l'utilisateur actif. 
Pour ça, il faut généralement ajouter l'utilisateur au groupe Docker, et redémarrer la session.
Il est possible de vérifier si l'installation est fonctionnelle en lançant
```
docker image ls
```
Si la commande échoue, l'installation de Docker est à revoir.
Pour ajouter le Docker au groupe utilisateur réaliser les commandes suivante :
```
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker 
```

### Étapes
1. Cloner ce dépôt
2. Cloner l'image Docker : ` docker pull karmateam/karma-crosscompiler-nogtk`. Il est possible de faire les étapes 3 et 4 pendant ce temps.
3. Récupérer l'archive contenant les librairies pour Raspi ici : https://drive.google.com/open?id=1xslCVDkM9jt5LxSARN-TDuqKrP2hwnmI
4. L'extraire dans le dossier `toolsChain` du workspace
5. Lancer la configuration de l'environnement : `make setup-env`

*Cette dernière commande va récupérer les include nécessaire à Eclipse sur le Docker pour son bon fonctionnement.*

À partir de là, il suffit de lancer Eclipse avec comme Workspace ce dossier, d'importer les dépôts des différents projets, et voilà !

## Évolutions à prévoir
* Il va y avoir un problème avec l'utilisation de la cmn-lib dans les autres projets.
