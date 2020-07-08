# Hébergement

Avril est hébergée avec [`docker-compose`](https://docs.docker.com/compose/).

Elle est actuellement constituée de 3 webservices :
- phoenix : l'app d'Avril historique
- nuxt_profile : le profil de l'utilisateur une fois connecté, dont la code base est disponible là : https://github.com/StartupsPoleEmploi/avril-profil
- nuxt_booklet : le formulaire de dématarialisation du livret 1, dont la code base est disponible là : https://github.com/StartupsPoleEmploi/avril-livret1

Ainsi que des containers génériques :
- postgres : l'excellent système de base de données SQL
- nginx : le proxy qui route le traffic entrant
- minio : un object storage open source, alternative à Amazon S3

<!-- MarkdownTOC -->

- [Déploiement](#d%C3%A9ploiement)
- [Rolling update](#rolling-update)

<!-- /MarkdownTOC -->

## Déploiement

Pour déployer un nouveau serveur, il faut :

1. Installer [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/)
2. Cloner le repo sur le serveur (le standard PE est `/home/docker`): `git clone https://github.com/StartupsPoleEmploi/avril /home/docker`
3. Cloner le repo du profil dans le même dossier qu'`avril` : : `git clone https://github.com/StartupsPoleEmploi/avril-profil /home/docker`
3. Cloner le repo du livret 1 dans le même dossier qu'`avril` : : `git clone https://github.com/StartupsPoleEmploi/avril-livret1 /home/docker`
4. Ajuster les variables d'environnement [.env](../.env) (un fichier [.env.example](../.env.example) est fournit)
5. Si besoin, placer les certificats SSL dans [/root/ssl/avril.pole-emploi.fr/](/root/ssl/avril.pole-emploi.fr/) comme précisé dans la conf [/nginx/avril.pole-emploi.fr.conf](/nginx/avril.pole-emploi.fr.conf)
6. Télécharger un dump de la DB, le nommer `latest.dump` le placer dans [db/dumps](./db/dumps)

7. Builder le container de l'app considéré:

```
docker-compose build
```

8. Démarrer le serveur

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

> La commande est disponible dans le script suivant : [`console_local.sh`](/scripts/utils/scripts/utils/console_local.sh).


11. PSQL

Pour avoir un psql ouvert avec la BDD :

```
docker-compose exec postgres bash -c 'psql -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER'
```

> La commande est disponible dans le script suivant : [`psql.sh`](/scripts/utils/scripts/utils/psql.sh).


12. DB Backup

Pour générer un backup :

```
docker-compose exec postgres bash -c 'pg_dump -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -F c -f /pg-dump/latest.dump'
```

> La commande est disponible dans le script suivant à exécuter depuis sa machine distante : [`backup_remote.sh`](/scripts/utils/scripts/utils/backup_remote.sh).


**Backups automatiques** : le script `/root/avril-backup.sh` est en charge de déclencher un backup quotidiennement et de le sauvegarder dans `/mnt/backups/avril`. Ces backups sont conservés une semaine.

13. DB Restore

```
docker-compose exec postgres bash -c 'pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER /pg-dump/latest.dump'
```

> La commande est disponible dans le script suivant : [`backup_restore.sh`](/scripts/utils/scripts/utils/backup_restore.sh).


## Rolling update

Pour mettre à jour l'un des 3 services, il suffit de lancer le script de rolling-update :

Depuis le serveur :

```
../avril/scripts/utils/deploy_local.sh <REPO_NAME>
```

Ou depuis sa machine distante :

```
../avril/scripts/utils/deploy_remote.sh <REPO_NAME>
```

Avec `<REPO_NAME>` qui a pour possible valeurs : `avril`/`avril-profil`/`avril-livret1`.


Ce script exécute les opérations suivantes :
- initialise et lance un container avec la nouvelle version du code
- attend que le service soit "healthy"
- redémarre nginx qui prend en compte la nouvelle instance en parallèle
- stop la précédente instance puis la supprime
- nginx ne route que sur l'instance qui reste active

Le tout, sans downtime. :)

**Limitations**:

Les rolling updates ne fonctionnent que pour ces 3 applications, car elles vérifients les critères suivants :
- ne servent pas de proxy => ne fonctionne pas pour le container nginx (dans ce cas il faut faire un `docker-compose restart nginx` qui entrainera un peu de downtime).
- ne sont pas en concurrence entre les instances : si 2 instances tournent en parallèle, elles ne se gênent pas l'une de l'autre. => ne fonctionne pas pour minio et postgres qui sont basées sur les mêmes données physiques.

