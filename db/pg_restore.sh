#!/bin/bash
# wait-for-postgres.sh

set -e

export PGPASSWORD=$POSTGRES_PASSWORD

DUMP_FILE="/host/latest.dump"


until psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

count=$(psql -t -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c 'select count(*) from schema_migrations;';)

if [[ $count -gt 0 ]]; then
  echo "Database $POSTGRES_DB has migrations: no need to seed"
else
  echo "Creating $POSTGRES_DB and seeding it"

  createdb -h $POSTGRES_HOST -U $POSTGRES_USER -w $POSTGRES_DB

  if [[ -f $DUMP_FILE ]]; then
    pg_restore --verbose --clean --create --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -w $DUMP_FILE
  else
    echo "Dump file $DUMP_FILE not found"
  fi
fi

exit 0