#!/bin/bash
# wait-for-postgres.sh

set -e
export PGPASSWORD=$POSTGRES_PASSWORD

cmd="$@"

until psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c '\q'; do
  >&2 echo "[WAIT] Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "[DONE] Postgres is up - executing command"
exec $cmd