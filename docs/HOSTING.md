# Hébergement

## Déploiement

L'application est utilisée via [Docker Swarm](https://docs.docker.com/engine/swarm/).

Pour déployer un nouveau serveur, il faut :

1. Installer [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/)
2. Cloner le repo sur le serveur
3. Ajuster les variables d'environnement [.env](../.env) (un fichier [.env.example](../.env.example) est fournit)
4. Télécharger un dump de la DB, le nommer latest.dump le placer dans [db/](./db)

5. Builder le container de l'app considéré:

```
docker-compose build
```

6. Deploy

```
docker stack deploy -c docker-stack.yml -c docker-compose.yml avril
```

Vous pouvez ignorer les warnings.

7. Rentrer dans un container elixir pour créer la DB:

```
docker exec -it $(docker ps -a | grep "app" | awk '{print $1}' | head -n 1) mix ecto.create
```

8. Rentrer dans le container postgres pour lancer `pg_restore`:

```
docker exec -it $(docker ps -a | grep "postgres" | awk '{print $1}') bash
createdb -h $POSTGRES_HOST -U $POSTGRES_USER -W $POSTGRES_DB
pg_restore --verbose --clean --create --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER /app/db/latest.dump
```

9. Suivi

- Voir l'état des services : `docker stack ps avril`
- Voir les logs de l'app : `docker service logs --tail=100 -f avril_app`

10. DB Backup

```
docker exec -it $(docker ps -a | grep "postgres" | awk '{print $1}') bash
pg_dump --verbose -h $PGHOST -d $PGDB -U $PGUSER /app/db/latest.dump
```

## Rolling update

Le rebuild du container n'est pas obligatoire mais suggéré si des dépendances ont été modifées :
- dans [mix.exs](./mix.exs)
- ou dans [package.json](./assets/package.json)

Dans ce cas, relancer d'abord :

```
docker-compose build
```

Puis pour mettre à jour le code, la commande est la même :

```
docker stack deploy -c docker-stack.yml -c docker-compose.yml avril
```

