#!/bin/bash

set -e

export PGPASSWORD=$POSTGRES_PASSWORD

DUMP_FILE="latest.dump"
LOCK_FILE="init.lock"

cd "$(dirname "$0")"

touch $LOCK_FILE

if createdb -h $POSTGRES_HOST -U $POSTGRES_USER -w $POSTGRES_DB; then
  echo "DB $POSTGRES_DB created";
else
  echo "DB $POSTGRES_DB already existed";
fi

if psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c 'select count(*) from schema_migrations;'; then
  echo "FINISH: Database $POSTGRES_DB has migrations: no need to seed.";
else
  echo "Creating $POSTGRES_DB and seeding it";

  if [[ -f $DUMP_FILE ]]; then
    pg_restore --verbose --clean --no-acl --no-owner -h $POSTGRES_HOST -d $POSTGRES_DB -U $POSTGRES_USER -w $DUMP_FILE || true
    echo "Checking restore";
    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c 'select count(*) from schema_migrations;' || true
    echo "[DONE] Database seeded";
  else
    echo "[DONE] Dump file $DUMP_FILE not found"
  fi
fi

rm $LOCK_FILE

exit 0