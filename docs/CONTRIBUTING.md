# Contribuer et améliorer Avril

Nous accueillons les contributions de tous les développeurs volontaires à notre base de code, sous la forme de pull requests.

## Dépendences

L'application est codée avec le language [Elixir](https://elixir-lang.org/) et utilise le [framework Phoenix](https://phoenixframework.org/) et stocke ses données dans une base [PostgreSQL](https://www.postgresql.org/). [NodeJS](https://nodejs.org) est nécessaire pour générer le front.

En outre, elle utilise [wkhtmltopdf](https://wkhtmltopdf.org/) pour générer des documents PDF ainsi que la librairie [Goon](https://github.com/alco/goon).

> #### A propos de Phoenix
>
> Phoenix est un framework très inspiré de [Ruby On Rails](https://rubyonrails.org/).
>
> Aussi, [FROM_RAILS.md](FROM_RAILS.md) rassemble quelques équivalents pour ceux qui viennent de ce monde.

## Installation

Il est possible d'installer directement les dépendences sur sa machine, mais il est préconisé d'utiliser [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/) pour une installation accélérée. En effet, l'ensemble des dépendances sus-citées sont installées grâce au [Dockerfile](/Dockerfile).

Une fois `docker-compose` installé, il ne reste plus qu'à faire `docker-compose build` puis `docker-compose run --rm --service-ports app bash` (que l'on recommande d'aliaser en `dkp`, [plus d'infos](https://augustin-riedinger.fr/en/resources/using-docker-as-a-development-environment-part-1/)) pour ouvrir un terminal dans le docker applicatif.

## Variables d'environnement

Dupliquer le fichier `.env.example` en `.env`. Récupérer les clés API des différents services utilisés (Algolia, Crisp).

## Installer le dump de la BDD

Télécharger un dump de la BDD (probablement via [flynn](https://flynn.io/) si accès à la prod : `flynn pg dump -f db/latest.dump`).

Copier le dump dans `[/db](../db)` pour qu'il soit accessible dans un docker.

Puis exécuter :

- `docker-compose run --rm app bash`
- Dans le docker, exécuter : `mix ecto.create` pour créer la BDD
- Puis dans un autre terminal, exécuter : `docker-compose exec postgres pg_restore --verbose --clean --no-acl --no-owner -h postgres -d vae_dev -U postgres /pg-dump/latest.dump`

> Attention : cela génère un warning, ne pas hésiter à lancer deux fois la requête pour que le restore se passe bien ([suivre l'issue](https://github.com/flynn/flynn/issues/4525)).

## Démarrer le serveur

Une fois dans le docker, `iex -S mix phx.server` démarre un serveur disponible à http://localhost:4000/ ainsi qu'une console interactive dans le terminal.

## Démarrer PG Admin

[PG Admin](https://www.pgadmin.org/) est un programme GUI qui permet d'inspecter simplement le contenu de sa base de donnée. La dernière version est un client web à 100%, aussi, il est dockerisé pour plus de facilité.

`docker-compose up -d pgadmin` puis accessible via http://localhost.

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

