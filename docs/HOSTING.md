# Hébergement

Avril est hébergée avec [`docker-compose`](https://docs.docker.com/compose/).

Elle est actuellement constituée de 2 webservices :
- phoenix : l'app d'Avril historique
- nuxt : le formulaire de dématarialisation du livret 1, dont la code base est disponible là : https://github.com/StartupsPoleEmploi/avril-livret1

## Déploiement

Pour déployer un nouveau serveur, il faut :

1. Installer [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/)
2. Cloner le repo sur le serveur (le standard PE est `/home/docker`)
3. Cloner le repo du livret 1 dans le même dossier qu'`avril` : https://github.com/StartupsPoleEmploi/avril-livret1
4. Ajuster les variables d'environnement [.env](../.env) (un fichier [.env.example](../.env.example) est fournit)
5. Si besoin, placer les certificats SSL dans [/root/ssl/avril.pole-emploi.fr/](/root/ssl/avril.pole-emploi.fr/) comme précisé dans la conf [/nginx](/nginx)
6. Télécharger un dump de la DB, le nommer `latest.dump` le placer dans [db/dumps](./db/dumps)

7. Builder le container de l'app considéré:

```
docker-compose build
```

8. Deploy

```
docker-compose up -d
```

9. Suivi

- Voir l'état des services : `watch -n 5 docker ps -a`
- Voir les logs de l'app : `docker-compose logs --tail=100 -f`

10. Console

Pour avoir une console dynamique avec l'environnement phoenix chargé :

```
docker-compose exec phoenix iex -S mix
```

11. PSQL

Pour avoir un psql ouvert avec la BDD :

```
docker-compose exec postgres bash -c 'psql -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER'
```

12. DB Backup

Pour générer un backup :

```
docker-compose exec postgres bash -c 'pg_dump -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -F c -f /pg-dump/latest.dump'
```

**Backups automatiques** : le script `/root/avril-backup.sh` est en charge de déclencher un backup quotidiennement et de le sauvegarder dans `/mnt/backups/avril`. Ces backups sont conservés une semaine.

13. DB Restore

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


