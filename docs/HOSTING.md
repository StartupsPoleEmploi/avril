# Hébergement

Avril est hébergée avec [`docker-compose`](https://docs.docker.com/compose/).

Elle est actuellement constituée de 2 webservices :
- phoenix : l'app d'Avril historique
- nuxt : le formulaire de dématarialisation du livret 1

## Déploiement

Pour déployer un nouveau serveur, il faut :

1. Installer [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/)
2. Cloner le repo sur le serveur
3. Ajuster les variables d'environnement [.env](../.env) (un fichier [.env.example](../.env.example) est fournit)
4. Si besoin, placer les certificats SSL dans [/root/ssl/avril.pole-emploi.fr/](/root/ssl/avril.pole-emploi.fr/) comme précisé dans la conf [/nginx](/nginx)
5. Télécharger un dump de la DB, le nommer `latest.dump` le placer dans [db/dumps](./db/dumps)

5. Builder le container de l'app considéré:

```
docker-compose build
```

6. Deploy

```
docker-compose up -d
```

9. Suivi

- Voir l'état des services : `watch -n 5 docker ps -a`
- Voir les logs de l'app : `docker-compose logs --tail=100 -f`

10. DB Backup

```
docker-compose exec postgres bash -c 'pg_dump -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -F c -f /pg-dump/latest.dump'
```

**Backups automatiques** : le script `/root/avril-backup.sh` est en charge de déclencher un backup quotidiennement et de le sauvegarder dans `/mnt/backups/avril`. Ces backups sont conservés une semaine.

11. DB Restore

```
docker-compose exec postgres bash -c 'pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER /pg-dump/latest.dump'
```

## Rolling update

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


