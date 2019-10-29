# Hébergement

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

7. Rentrer dans un container elixir pour créer la DB:

```
docker exec -it $(docker ps -a | grep "app" | awk '{print $1}' | head -n 1) mix ecto.create
```

8. Rentrer dans le container postgres pour lancer pg_restore:

```
docker exec -it $(docker ps -a | grep "postgres" | awk '{print $1}') bash
pg_restore --verbose --clean --create --no-acl --no-owner -h $PGHOST -d $PGDB -U $PGUSER /app/db/latest.dump
```

9. Suivi

- Voir l'état des services : `docker stack ps avril`
- Voir les logs de l'app : `docker service logs --tail=100 -f avril_app`
