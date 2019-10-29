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

if createdb -h $POSTGRES_HOST -U $POSTGRES_USER -w $POSTGRES_DB; then
  echo "DB $POSTGRES_DB created";
fi

if psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c 'select count(*) from schema_migrations;'; then
  echo "FINISH: Database $POSTGRES_DB has migrations: no need to seed."
else
  echo "Creating $POSTGRES_DB and seeding it"

  if [[ -f $DUMP_FILE ]]; then
    pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -w $DUMP_FILE || true
    echo "Checking restore"
    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c 'select count(*) from schema_migrations;' || true
    echo "FINISH: Database seeded"
  else
    echo "FINISH: Dump file $DUMP_FILE not found"
  fi
fi

exit 0