# Monitorer

Une fois connecté sur le serveur, voici les différents checks et actions possibles.

<!-- MarkdownTOC -->

- [Vérifier que tout va bien](#v%C3%A9rifier-que-tout-va-bien)
  - [Avec `docker`](#avec-docker)
  - [Avec `docker-compose`](#avec-docker-compose)
- [Si ça n'est pas le cas ?](#si-%C3%A7a-nest-pas-le-cas-)
  - [Simple redémarrage d'un service](#simple-red%C3%A9marrage-dun-service)
  - [Cas particulier des services web](#cas-particulier-des-services-web)
  - [Voir ce qui se passe](#voir-ce-qui-se-passe)

<!-- /MarkdownTOC -->


## Vérifier que tout va bien

### Avec `docker`

Dans n'importe quel `cwd` de la machine, il est possible de vérifier qu'Avril tourne correctement en faisant:

```
$ docker ps -a
CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS                  PORTS                                      NAMES
9bef07f8b6XX        avril_phoenix              "/app/scripts/init-p…"   5 hours ago         Up 4 hours (healthy)                                               avril_phoenix_X
0198632e02XX        node:latest                "docker-entrypoint.s…"   25 hours ago        Up 25 hours (healthy)                                              avril_nuxt_X
149d549a94XX        postgres:11.6-alpine       "docker-entrypoint.s…"   5 days ago          Up 5 days (healthy)     5432/tcp                                   avril_postgres_1
fd81355842XX        nginx:latest               "nginx -g 'daemon of…"   5 days ago          Up 4 hours (healthy)    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   avril_nginx_1
# d'autres containers peuvent aussi tourner
```

Tout est en ordre si tous les containers ont pour `STATUS` `(healthy)`.

### Avec `docker-compose`

Toutefois, il est préférable de monitorer depuis le répertoire où `docker-compose` a été lancé `/home/docker/avril` :

```
$ cd /home/docker/avril
$ docker-compose ps
      Name                    Command                  State                        Ports
-----------------------------------------------------------------------------------------------------------
avril_nginx_1      nginx -g daemon off;             Up (healthy)   0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp
avril_nuxt_5       docker-entrypoint.sh yarn  ...   Up (healthy)
avril_phoenix_9    /app/scripts/init-phoenix.sh     Up (healthy)
avril_postgres_1   docker-entrypoint.sh postgres    Up (healthy)   5432/tcp
```

Idem, les containers doivent avoir pour `State` `Up (healthy)`.

Toutes les commandes `docker-compose` devront être exécutées depuis ce dossier.

## Si ça n'est pas le cas ?

### Simple redémarrage d'un service

Chaque container peut être relancé avec les commandes suivantes :

- `docker-compose restart <SERVICE_NAME>`: la liste des services est disponible dans [`docker-compose.yml`](../docker-compose.yml). Ex: `docker-compose restart postgres` (et non `avril_postgres_1`).
- Ou bien avec docker `docker restart <CONTAINER_ID>`. Ex: `docker restart fd81355842XX`

Le container relancé va d'abord être en état `Starting` avant de passer normalement à `Up (healthy)` à nouveau.

### Cas particulier des services web

Les services web (`phoenix` et `nuxt`) sont accessibles après être passés par le reverse proxy d'`nginx`.

Plutôt que de les `restart` simplement, ce qui fonctionnerait mais entrainerait un downtime s'ils sont `Up` actuellement, il est possible de les mettre à jour en démarrant une nouvelle instance en parallèle.

Pour cela la commande est (depuis `/home/docker/avril`):

`./scripts/utils/docker_update <SERVICE_NAME>`. Ex: `./scripts/utils/docker_update phoenix`

Plus de détails sur le fonctionnement du script est disponible [ici](./HOSTING.md#rolling-update).

### Voir ce qui se passe

#### Inspecter les logs

Les logs des différents containers sont accesibles via la commande :

```
docker-compose logs --tail=100 -f
```

Pour un service en particulier :

```
docker-compose logs --tail=100 -f <SERVICE_NAME>
```

#### Erreur de compilation

Si le container `phoenix` ne compile pas, il ne démarrera pas. L'erreur devrait alors être visible dans les logs dédiés :

```
docker-compose logs --tail=100 -f phoenix
```

#### Problème de configuration `nginx`

Il est possible de rapidement vérifier que la configuration `nginx` ne pose pas de problème via la commande

```
docker-compose exec nginx nginx -t
```

Ex: les fichiers du certificat SSL d'Avril qui ne sont pas au bon endroit.

#### Restore un backup de la BDD

Pour générer un backup de la BDD (à supposer que le service `postgres`) soit `Up`, la commande est :

```
docker-compose exec postgres bash -c 'pg_dump -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -F c -f /pg-dump/<FILENAME>.dump'
```

Le fichier `<FILENAME>.dump` est alors disponible à `/home/docker/avril/db/dumps`.

Si la BDD n'est pas disponible, il est possible de restore un précédent backup quotidien automatique, disponibles dans `/mnt/backups/avril`.

Il faut alors le copier dans `/home/docker/avril/db/dumps` et le nommer `latest.dump`.

Plusieurs cas de figure:

##### 1. Le container `postgres` est `Up`

```
docker-compose exec postgres bash -c 'pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER /pg-dump/latest.dump'
```

##### 2. Le container `postgres` est `exited` mais `docker-compose run` fonctionne

Après avoir essayé de le redémarrer (`docker-compose restart postgres`) sans succès, il est possible de démarrer une autre instance pour lancer le restore:

```
docker-compose run --rm postgres bash -c 'pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER /pg-dump/latest.dump'
```

##### 3. Le container `postgres` est `exited` et `docker-compose run` ne fonctionne pas

Il faut réinitiliser intégralement la BDD.

1. S'assurer que `postgres` est bien coupé : `docker-compose stop postgres`
2. Supprimer l'instance du container : `docker-compose rm postgres`
3. **DANGEREUX**: Supprimer les données `postgres` : `sudo rm -rf db/data`
4. **IMPORTANT** : Placer le backup dans `/home/docker/avril/db/dumps` et nommer `latest.dump`
5. Lancer le container postgres : `docker-compose start postgres`

Le script d'initialisation de la BDD détectera qu'aucune donnée n'est présente et commencera pas restore `latest.dump` avant de démarrer normalement.

