# Contribuer et améliorer Avril

Nous accueillons les contributions de tous les développeurs volontaires à notre base de code, sous la forme de pull requests.

<!-- MarkdownTOC -->

- [Dépendences](#d%C3%A9pendences)
- [Clôner les sources](#cl%C3%B4ner-les-sources)
- [Installation](#installation)
- [Variables d'environnement](#variables-denvironnement)
- [Installer le dump de la BDD](#installer-le-dump-de-la-bdd)
- [Démarrer le serveur](#d%C3%A9marrer-le-serveur)
- [Démarrer PG Admin](#d%C3%A9marrer-pg-admin)
- [Configuration sous OSX](#configuration-sous-osx)

<!-- /MarkdownTOC -->

## Dépendences

L'application est codée avec le language [Elixir](https://elixir-lang.org/) et utilise le [framework Phoenix](https://phoenixframework.org/) et stocke ses données dans une base [PostgreSQL](https://www.postgresql.org/). [NodeJS](https://nodejs.org) est nécessaire pour générer le front.

En outre, elle utilise [wkhtmltopdf](https://wkhtmltopdf.org/) pour générer des documents PDF ainsi que la librairie [Goon](https://github.com/alco/goon).

> #### A propos de Phoenix
>
> Phoenix est un framework très inspiré de [Ruby On Rails](https://rubyonrails.org/).
>
> Aussi, [FROM_RAILS.md](FROM_RAILS.md) rassemble quelques équivalents pour ceux qui viennent de ce monde.

Avril est aussi composée de 2 applications front qui utilisent le framework [nuxt.js](https://nuxtjs.org) basée sur [NodeJS](https://nodejs.org) et [VueJS](https://vuejs.org).

## Clôner les sources

Avril est présentement composée de 3 applications indépendantes dont le code est enregistré dans 3 repos séparés :

- [avril](https://github.com/StartupsPoleEmploi/avril)
- [avril-profil](https://github.com/StartupsPoleEmploi/avril-profil)
- [avril-livret1](https://github.com/StartupsPoleEmploi/avril-livret1)

Il est nécessaire de cloner ces repos dans le même dossier racine et de ne pas les renommer.

```
cd ~/Workspace # votre dossier de travail

git clone git@github.com:StartupsPoleEmploi/avril.git && \
git clone git@github.com:StartupsPoleEmploi/avril-profil.git && \
git clone git@github.com:StartupsPoleEmploi/avril-livret1.git
```

## Installation

S'il est techniquement possible d'installer directement les dépendences sur sa machine, il est désormais **indispensable** d'utiliser [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/) pour une installation accélérée. En effet, l'ensemble des dépendances sus-citées sont installées grâce au [Dockerfile](/Dockerfile).

Une fois `docker-compose` installé, il ne reste plus qu'à faire `docker-compose build`.

## Variables d'environnement

Dupliquer le fichier `.env.example` en `.env`. Récupérer les clés API des différents services utilisés (Algolia/Mailjet).

## Installer le dump de la BDD

Télécharger un dump de la BDD si accès à la prod :

```
docker-compose exec postgres bash -c 'pg_dump -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -F c -f /pg-dump/latest.dump'
```

> La commande est disponible dans le script suivant à exécuter depuis sa machine distante : [`backup_remote.sh`](/scripts/utils/scripts/utils/backup_remote.sh).

Copier le dump dans `[/db/dumps](../db/dumps)` pour qu'il soit accessible dans un docker.

Celui-ci sera automatiquement *restore* lors du premier lancement du container `postgres`, à condition que le dossier `db/data` soit effectivement vide.

Sinon la commande manuelle sera, une fois le container `postgres` lancé :

```
docker-compose exec postgres bash -c 'pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER /pg-dump/latest.dump'
```

> La commande est disponible dans le script suivant : [`backup_restore.sh`](/scripts/utils/scripts/utils/backup_restore.sh).

## Démarrer le serveur

Une fois que l'on a:

```
./avril/<Ce Repo>
./avril/.env
./avril/docker-compose.override.yml
./avril/db/dumps/latest.dump
./avril/db/data/<VIDE>
./avril-profil/<Le repo avril-profil>
./avril-livret1/<Le repo avril-livret1>
```

il est temps de démarrer le serveur avec :

```
docker-compose up
```

Les différents services démarrent, et l'application est disponible à l'adresse : http://localhost

## Démarrer PG Admin

[PG Admin](https://www.pgadmin.org/) est un programme GUI qui permet d'inspecter simplement le contenu de sa base de donnée. La dernière version est un client web à 100%, aussi, il est dockerisé pour plus de facilité.

Il est conseillé de l'ajouter dans son environnement local via le fichier `docker-compose.override.yml` (dupliquer [`docker-compose.override.example.yml`](../docker-compose.override.example.yml))

`docker-compose up -d pgadmin` si le container n'est pas démarré puis accessible via http://localhost:8080.

Les logins utilisés sont ceux définis dans `.env`:

```
PGADMIN_DEFAULT_EMAIL=email@example.com
PGADMIN_DEFAULT_PASSWORD=password
```

Une fois connecté, vous pouvez a minima accéder à la BDD locale via la config suivante :

```
Name : Avril Local
Host name : postgres
Port : 5432
Username : postgres
Password :
```

<!--
## Configuration sous OSX

Il semblerait qu'il faille ajouter les configurations suivantes dans `docker-compose.override.yml` pour que `postgres` fonctionne sous OSX:

```
version: “3.6”
services:
  postgres:
    volumes:
      - $PWD/db/data:/var/lib/postgresql/data
      - $PWD/db/dumps/latest.dump:/pg-dump/latest.dump
```
 -->
