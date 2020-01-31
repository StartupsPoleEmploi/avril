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
docker-compose up -d
```

<!-- ```
docker stack deploy --prune -c docker-stack.yml -c docker-compose.yml avril
```
 -->

<!-- 7. Rentrer dans un container elixir pour créer la DB:

```
docker exec -it $(docker ps -a | grep "app" | awk '{print $1}' | head -n 1) mix ecto.create
```

8. Rentrer dans le container postgres pour lancer `pg_restore`:

```
docker exec -it $(docker ps -a | grep "postgres" | awk '{print $1}') bash
/host/pg_restore.sh
```
 -->
9. Suivi

- Voir l'état des services : `watch -n 5 docker ps -a`
- Voir les logs de l'app : `docker-compose logs --tail=100 -f`

<!-- - Voir l'état des services : `docker stack ps avril`
- Voir les logs de l'app : `docker service logs --tail=100 -f avril_app` -->

10. DB Backup

```
docker-compose exec postgres bash
pg_dump --verbose -h $PGHOST -d $PGDB -U $PGUSER /app/db/latest.dump
```

## Rolling update

Avril est actuellement constituée de 2 webservices :
- phoenix : l'app d'Avril historique
- nuxt : le formulaire de dématarialisation du livret 1

Pour mettre à jour l'un de ces deux services, il faut

1. Prendre la dernière version du code :

- phoenix : `cd /home/docker/avril && git pull`
- nuxt : `cd /home/docker/avril-livret1 && git pull`

2. Lancer le script de rolling-update :

```
../avril/scripts/utils/docker-update.sh <SERVICE_NAME>
```

Ce script exécute les opérations suivantes :
- initialize et lance un container avec la nouvelle version du code
- attend que le service soit "healthy"
- redémarre nginx qui prend en compte la nouvelle instance en parallèle
- stop la précédente instance puis la supprime
- nginx ne route que sur l'instance qui reste active


